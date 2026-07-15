#!/usr/bin/env python3
"""Run one production STM32 QMK ELF in the pinned Renode environment."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import subprocess
import sys
import tempfile


ROOT = pathlib.Path(__file__).resolve().parent
ANSI_ESCAPE = re.compile(r"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1b\\))")
RETURN_ADDRESS = 0x2001FFF0


def arguments() -> argparse.Namespace:
    """Parse and validate the emulator command line."""
    parser = argparse.ArgumentParser()
    parser.add_argument("--board", required=True, choices=("planck", "q15"))
    parser.add_argument("--firmware", required=True, type=pathlib.Path)
    return parser.parse_args()


def sha256(path: pathlib.Path) -> str:
    """Return the hexadecimal SHA-256 digest for one firmware ELF."""
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def lookup_calls(fixture: dict[str, object]) -> list[list[object]]:
    """Expand a host fixture into calls against the embedded Swift C ABI."""
    layer_count = int(fixture["layerCount"])
    matrix_rows = int(fixture["matrixRows"])
    matrix_columns = int(fixture["matrixColumns"])
    encoder_count = int(fixture["encoderCount"])
    calls: list[list[object]] = [
        ["qmk_swift_layer_count", 0, 0, 0, layer_count, 0xFF],
        ["qmk_swift_encoder_count", 0, 0, 0, encoder_count, 0xFF],
        ["qmk_swift_layout_id", 0, 0, 0, int(fixture["layoutID"]), 0xFFFFFFFF],
        [
            "qmk_swift_semantic_fingerprint",
            0,
            0,
            0,
            int(fixture["semanticFingerprint"]),
            0xFFFFFFFF,
        ],
        [
            "qmk_swift_style_fingerprint",
            0,
            0,
            0,
            int(fixture["styleFingerprint"]),
            0xFFFFFFFF,
        ],
    ]

    matrix_lookups = (
        ("qmk_swift_keycode_at", "keycodes", 0xFFFF),
        ("qmk_swift_semantic_id_at", "semanticIDs", 0xFFFF),
        ("qmk_swift_style_id_at", "styleIDs", 0xFFFF),
        ("qmk_swift_style_color_at", "styleColors", 0xFFFFFFFF),
    )
    matrix_value_count = layer_count * matrix_rows * matrix_columns
    for symbol, fixture_key, mask in matrix_lookups:
        values = fixture[fixture_key]
        if not isinstance(values, list) or len(values) != matrix_value_count:
            raise ValueError(f"invalid {fixture_key} fixture length")
        for index, expected in enumerate(values):
            layer, cell = divmod(index, matrix_rows * matrix_columns)
            row, column = divmod(cell, matrix_columns)
            calls.append([symbol, layer, row, column, int(expected), mask])

    encoder_lookups = (("qmk_swift_encoder_keycode_at", "encoderKeycodes"),)
    encoder_value_count = layer_count * encoder_count * 2
    for symbol, fixture_key in encoder_lookups:
        values = fixture[fixture_key]
        if not isinstance(values, list) or len(values) != encoder_value_count:
            raise ValueError(f"invalid {fixture_key} fixture length")
        for index, expected in enumerate(values):
            layer, direction_index = divmod(index, encoder_count * 2)
            encoder, direction = divmod(direction_index, 2)
            calls.append([symbol, layer, encoder, direction, int(expected), 0xFFFF])

    return calls


def renode_script(board: str, calls: list[list[object]]) -> str:
    """Create a Renode scenario that drives pure functions in the production ELF."""
    call_data = json.dumps(calls, separators=(",", ":"))
    first = calls[0]
    return f'''include @{ROOT / "platforms" / f"{board}.resc"}

set lookup_driver
"""
from Antmicro.Renode.Peripherals.CPU import RegisterValue
if 'lookup_calls' not in globals():
    lookup_calls = {call_data}
    lookup_index = 0
    lookup_addresses = {{name: cpu.Bus.GetSymbolAddress(name) for name in set(call[0] for call in lookup_calls)}}

call = lookup_calls[lookup_index]
actual = int(cpu.GetRegister(0).RawValue) & call[5]
if actual != call[4]:
    print('OBBUT_STM32_LOOKUP_MISMATCH board={board} index={{0}} symbol={{1}} args={{2}},{{3}},{{4}} expected={{5}} actual={{6}}'.format(lookup_index, call[0], call[1], call[2], call[3], call[4], actual))
    cpu.PC = RegisterValue.Create({RETURN_ADDRESS + 2}, 32)
else:
    lookup_index += 1
    if lookup_index == len(lookup_calls):
        print('OBBUT_STM32_LOOKUPS_OK board={board} values={{0}}'.format(lookup_index))
        cpu.PC = RegisterValue.Create({RETURN_ADDRESS + 2}, 32)
    else:
        call = lookup_calls[lookup_index]
        cpu.SetRegister(0, RegisterValue.Create(call[1], 32))
        cpu.SetRegister(1, RegisterValue.Create(call[2], 32))
        cpu.SetRegister(2, RegisterValue.Create(call[3], 32))
        cpu.SetRegister(14, RegisterValue.Create({RETURN_ADDRESS + 1}, 32))
        cpu.PC = lookup_addresses[call[0]]
"""

sysbus WriteWord {RETURN_ADDRESS + 2} 0xE7FE
cpu AddHook {RETURN_ADDRESS} $lookup_driver
cpu SetRegister 0 {first[1]}
cpu SetRegister 1 {first[2]}
cpu SetRegister 2 {first[3]}
cpu SetRegister 14 {RETURN_ADDRESS + 1}
cpu PC `sysbus GetSymbolAddress "{first[0]}"`
emulation RunFor "0.1"
quit
'''


def main() -> int:
    """Execute Renode and reduce its output to a stable test result."""
    args = arguments()
    firmware = args.firmware.resolve()
    if not firmware.is_file():
        raise SystemExit(f"firmware ELF does not exist: {firmware}")

    fixture_path = ROOT / "fixtures" / f"{args.board}.json"
    fixture = json.loads(fixture_path.read_text())
    calls = lookup_calls(fixture)
    with tempfile.NamedTemporaryFile(mode="w", suffix=".resc") as scenario:
        scenario.write(renode_script(args.board, calls))
        scenario.flush()
        command = [
            "renode",
            "--disable-gui",
            "--console",
            "-e",
            f"$firmware=@{firmware}",
            scenario.name,
        ]
        completed = subprocess.run(command, capture_output=True, text=True, timeout=90, check=False)
    output = ANSI_ESCAPE.sub("", completed.stdout + completed.stderr).replace("\r", "")
    marker = f"OBBUT_STM32_BOOT_OK board={args.board} scans=250"
    swift_marker = f"OBBUT_STM32_SWIFT_READY board={args.board}"
    fault_marker = f"OBBUT_STM32_FAULT board={args.board}"
    lookup_marker = f"OBBUT_STM32_LOOKUPS_OK board={args.board} values={len(calls)}"
    mismatch_marker = f"OBBUT_STM32_LOOKUP_MISMATCH board={args.board}"
    errors = [line for line in output.splitlines() if "[ERROR]" in line or "Unhandled exception" in line]

    if (
        completed.returncode != 0
        or marker not in output
        or swift_marker not in output
        or lookup_marker not in output
        or fault_marker in output
        or mismatch_marker in output
        or errors
    ):
        sys.stderr.write(output)
        print(json.dumps({
            "status": "failed",
            "board": args.board,
            "firmware": str(firmware),
            "sha256": sha256(firmware),
            "returnCode": completed.returncode,
            "bootMarker": marker in output,
            "swiftMarker": swift_marker in output,
            "lookupMarker": lookup_marker in output,
            "lookupMismatch": mismatch_marker in output,
            "faultMarker": fault_marker in output,
            "errors": errors,
        }))
        return 1

    print(json.dumps({
        "status": "passed",
        "board": args.board,
        "firmware": str(firmware),
        "sha256": sha256(firmware),
        "matrixScans": 250,
        "lookupValues": len(calls),
        "firmwareKind": "production-elf",
    }))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
