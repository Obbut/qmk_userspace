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
PROTOCOL_BUFFER = 0x2001FE00


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

    keycodes = fixture["keycodes"]
    if not isinstance(keycodes, list):
        raise ValueError("invalid keycodes fixture")
    for index, expected in enumerate(keycodes):
        layer, cell = divmod(index, matrix_rows * matrix_columns)
        row, column = divmod(cell, matrix_columns)
        packed_position = column | (row << 8)
        calls.append(["keymap_key_to_keycode", layer, packed_position, 0, int(expected), 0xFFFF])

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

    encoder_keycodes = fixture["encoderKeycodes"]
    if not isinstance(encoder_keycodes, list):
        raise ValueError("invalid encoderKeycodes fixture")
    for index, expected in enumerate(encoder_keycodes):
        layer, direction_index = divmod(index, encoder_count * 2)
        encoder, direction = divmod(direction_index, 2)
        row = 252 if direction == 0 else 253
        packed_position = encoder | (row << 8)
        calls.append(["keymap_key_to_keycode", layer, packed_position, 0, int(expected), 0xFFFF])

    calls.extend([
        ["qmk_swift_process_record", 4, 1, 0, 1, 0xFF],
        ["qmk_swift_process_record", 4, 0, 0, 1, 0xFF],
    ])
    if fixture["outputName"] == "zsa_planck_ez_glow_obbut":
        calls.extend([
            ["qmk_swift_layer_state_set", 0b01100, 0, 0, 0b11100, 0xFFFFFFFF],
            ["qmk_swift_layer_state_set", 0b00100, 0, 0, 0b00100, 0xFFFFFFFF],
        ])
    else:
        calls.append(["qmk_swift_layer_state_set", 0b01100, 0, 0, 0b01100, 0xFFFFFFFF])
    calls.append(["qmk_swift_rgb_matrix_indicators", 0, 255, 0, 0, 0xFF])

    return calls


def add_fingerprint_byte(value: int, fingerprint: int) -> int:
    """Add one byte to a protocol FNV-1a fingerprint."""
    return ((fingerprint ^ value) * 16_777_619) & 0xFFFFFFFF


def append_uint16(target: list[int], value: int) -> None:
    """Append one little-endian 16-bit integer to a byte list."""
    target.extend((value & 0xFF, (value >> 8) & 0xFF))


def append_uint32(target: list[int], value: int) -> None:
    """Append one little-endian 32-bit integer to a byte list."""
    target.extend((value >> shift) & 0xFF for shift in (0, 8, 16, 24))


def protocol_entries(fixture: dict[str, object]) -> list[tuple[int, int, int]]:
    """Return protocol-ordered matrix and encoder entries from a host fixture."""
    matrix = list(zip(fixture["keycodes"], fixture["semanticIDs"], fixture["styleIDs"]))
    encoders = list(zip(
        fixture["encoderKeycodes"],
        fixture["encoderSemanticIDs"],
        fixture["encoderStyleIDs"],
    ))
    return [(int(keycode), int(semantic), int(style)) for keycode, semantic, style in matrix + encoders]


def keymap_fingerprint(fixture: dict[str, object], entries: list[tuple[int, int, int]]) -> int:
    """Calculate the protocol-v4 keymap fingerprint independently on the host."""
    seed: list[int] = []
    append_uint32(seed, int(fixture["layoutID"]))
    seed.extend((
        int(fixture["layerCount"]),
        int(fixture["matrixRows"]),
        int(fixture["matrixColumns"]),
        int(fixture["encoderCount"]),
        2,
    ))
    fingerprint = 2_166_136_261
    for value in seed:
        fingerprint = add_fingerprint_byte(value, fingerprint)
    for entry in entries:
        for value in entry:
            fingerprint = add_fingerprint_byte(value & 0xFF, fingerprint)
            fingerprint = add_fingerprint_byte((value >> 8) & 0xFF, fingerprint)
    return fingerprint


def protocol_responses(fixture: dict[str, object]) -> list[list[int]]:
    """Build expected metadata plus first and last keymap-chunk responses."""
    entries = protocol_entries(fixture)
    metadata = [0x4B, 0x4D, 0x41, 0x50, 4, 4]
    append_uint32(metadata, int(fixture["layoutID"]))
    metadata.extend((
        int(fixture["layerCount"]),
        int(fixture["matrixRows"]),
        int(fixture["matrixColumns"]),
        6,
        2,
        int(fixture["encoderCount"]),
    ))
    append_uint16(metadata, len(entries))
    append_uint32(metadata, keymap_fingerprint(fixture, entries))
    append_uint32(metadata, int(fixture["semanticFingerprint"]))
    append_uint32(metadata, int(fixture["styleFingerprint"]))
    metadata.extend((2, 0))

    def chunk(start: int) -> list[int]:
        """Encode one expected keymap chunk starting at an entry index."""
        selected = entries[start:start + 2]
        response = [0x4B, 0x4D, 0x41, 0x50, 4, 6]
        append_uint32(response, int(fixture["layoutID"]))
        append_uint16(response, start)
        append_uint16(response, len(entries))
        response.extend((len(selected), 0))
        for entry in selected:
            for value in entry:
                append_uint16(response, value)
        response.extend(0 for _ in range(32 - len(response)))
        return response

    return [metadata, chunk(0), chunk(len(entries) - 1)]


def protocol_request(message_type: int, start_index: int = 0) -> list[int]:
    """Return one zero-padded protocol request."""
    request = [0] * 32
    request[:6] = [0x4B, 0x4D, 0x41, 0x50, 4, message_type]
    request[6] = start_index & 0xFF
    request[7] = (start_index >> 8) & 0xFF
    return request


def renode_script(
    board: str,
    calls: list[list[object]],
    responses: list[list[int]],
    final_entry_index: int,
) -> str:
    """Create a Renode scenario that drives pure functions in the production ELF."""
    call_data = json.dumps(calls, separators=(",", ":"))
    response_data = json.dumps(responses, separators=(",", ":"))
    request_data = json.dumps([
        protocol_request(3),
        protocol_request(5),
        protocol_request(5, final_entry_index),
    ], separators=(",", ":"))
    first = calls[0]
    return f'''include @{ROOT / "platforms" / f"{board}.resc"}

set lookup_driver
"""
from Antmicro.Renode.Peripherals.CPU import RegisterValue
if 'lookup_calls' not in globals():
    lookup_calls = {call_data}
    lookup_index = 0
    lookup_addresses = {{name: cpu.Bus.GetSymbolAddress(name) for name in set(call[0] for call in lookup_calls)}}
    raw_receive_address = cpu.Bus.GetSymbolAddress('raw_hid_receive')
    protocol_requests = {request_data}

def launch_protocol(index):
    request = protocol_requests[index]
    for offset in range(len(request)):
        cpu.Bus.WriteByte({PROTOCOL_BUFFER} + offset, request[offset])
    cpu.SetRegister(0, RegisterValue.Create({PROTOCOL_BUFFER}, 32))
    cpu.SetRegister(1, RegisterValue.Create(32, 32))
    cpu.SetRegister(14, RegisterValue.Create({RETURN_ADDRESS + 1}, 32))
    cpu.PC = raw_receive_address

if lookup_index < len(lookup_calls):
    call = lookup_calls[lookup_index]
    actual = int(cpu.GetRegister(0).RawValue) & call[5]
    if actual != call[4]:
        print('OBBUT_STM32_LOOKUP_MISMATCH board={board} index={{0}} symbol={{1}} args={{2}},{{3}},{{4}} expected={{5}} actual={{6}}'.format(lookup_index, call[0], call[1], call[2], call[3], call[4], actual))
        cpu.PC = RegisterValue.Create({RETURN_ADDRESS + 2}, 32)
    else:
        lookup_index += 1
        if lookup_index == len(lookup_calls):
            print('OBBUT_STM32_LOOKUPS_OK board={board} values={{0}}'.format(lookup_index))
            cpu.Bus.WriteByte({PROTOCOL_BUFFER + 32}, 0)
            cpu.Bus.WriteByte({PROTOCOL_BUFFER + 33}, 0)
            launch_protocol(0)
        else:
            call = lookup_calls[lookup_index]
            cpu.SetRegister(0, RegisterValue.Create(call[1], 32))
            cpu.SetRegister(1, RegisterValue.Create(call[2], 32))
            cpu.SetRegister(2, RegisterValue.Create(call[3], 32))
            cpu.SetRegister(14, RegisterValue.Create({RETURN_ADDRESS + 1}, 32))
            cpu.PC = lookup_addresses[call[0]]
else:
    protocol_index = cpu.Bus.ReadByte({PROTOCOL_BUFFER + 32})
    if protocol_index == len(protocol_requests):
        if cpu.Bus.ReadByte({PROTOCOL_BUFFER + 33}) == 0:
            print('OBBUT_STM32_PROTOCOL_OK board={board} responses={{0}}'.format(protocol_index))
        cpu.PC = RegisterValue.Create({RETURN_ADDRESS + 2}, 32)
    else:
        launch_protocol(protocol_index)
"""

set protocol_send
"""
if 'protocol_responses' not in globals():
    protocol_responses = {response_data}
address = int(cpu.GetRegister(0).RawValue)
length = int(cpu.GetRegister(1).RawValue)
protocol_index = cpu.Bus.ReadByte({PROTOCOL_BUFFER + 32})
actual = [cpu.Bus.ReadByte(address + index) for index in range(length)]
expected = protocol_responses[protocol_index]
if actual != expected:
    cpu.Bus.WriteByte({PROTOCOL_BUFFER + 33}, 1)
    difference = next((index for index in range(min(len(actual), len(expected))) if actual[index] != expected[index]), -1)
    print('OBBUT_STM32_PROTOCOL_MISMATCH board={board} response={{0}} byte={{1}} expected={{2}} actual={{3}}'.format(protocol_index, difference, expected[difference] if difference >= 0 else -1, actual[difference] if difference >= 0 else -1))
protocol_index += 1
cpu.Bus.WriteByte({PROTOCOL_BUFFER + 32}, protocol_index)
cpu.PC = cpu.LR
"""

sysbus WriteWord {RETURN_ADDRESS + 2} 0xE7FE
cpu AddHook {RETURN_ADDRESS} $lookup_driver
cpu AddHook `sysbus GetSymbolAddress "raw_hid_send"` $protocol_send
cpu SetRegister 0 {first[1]}
cpu SetRegister 1 {first[2]}
cpu SetRegister 2 {first[3]}
cpu SetRegister 14 {RETURN_ADDRESS + 1}
cpu PC `sysbus GetSymbolAddress "{first[0]}"`
emulation RunFor "0.25"
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
    responses = protocol_responses(fixture)
    final_entry_index = len(protocol_entries(fixture)) - 1
    with tempfile.NamedTemporaryFile(mode="w", suffix=".resc") as scenario:
        scenario.write(renode_script(args.board, calls, responses, final_entry_index))
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
    protocol_marker = f"OBBUT_STM32_PROTOCOL_OK board={args.board} responses={len(responses)}"
    protocol_mismatch_marker = f"OBBUT_STM32_PROTOCOL_MISMATCH board={args.board}"
    errors = [line for line in output.splitlines() if "[ERROR]" in line or "Unhandled exception" in line]

    if (
        completed.returncode != 0
        or marker not in output
        or swift_marker not in output
        or lookup_marker not in output
        or protocol_marker not in output
        or fault_marker in output
        or mismatch_marker in output
        or protocol_mismatch_marker in output
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
            "protocolMarker": protocol_marker in output,
            "protocolMismatch": protocol_mismatch_marker in output,
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
        "protocolResponses": len(responses),
        "firmwareKind": "production-elf",
    }))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
