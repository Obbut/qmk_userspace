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


ROOT = pathlib.Path(__file__).resolve().parent
ANSI_ESCAPE = re.compile(r"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1b\\))")


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


def main() -> int:
    """Execute Renode and reduce its output to a stable test result."""
    args = arguments()
    firmware = args.firmware.resolve()
    if not firmware.is_file():
        raise SystemExit(f"firmware ELF does not exist: {firmware}")

    script = ROOT / "platforms" / f"{args.board}.resc"
    command = [
        "renode",
        "--disable-gui",
        "--console",
        "-e",
        f"$firmware=@{firmware}",
        str(script),
    ]
    completed = subprocess.run(command, capture_output=True, text=True, timeout=90, check=False)
    output = ANSI_ESCAPE.sub("", completed.stdout + completed.stderr).replace("\r", "")
    marker = f"OBBUT_STM32_BOOT_OK board={args.board} scans=250"
    swift_marker = f"OBBUT_STM32_SWIFT_READY board={args.board}"
    fault_marker = f"OBBUT_STM32_FAULT board={args.board}"
    errors = [line for line in output.splitlines() if "[ERROR]" in line or "Unhandled exception" in line]

    if completed.returncode != 0 or marker not in output or swift_marker not in output or fault_marker in output or errors:
        sys.stderr.write(output)
        print(json.dumps({
            "status": "failed",
            "board": args.board,
            "firmware": str(firmware),
            "sha256": sha256(firmware),
            "returnCode": completed.returncode,
            "bootMarker": marker in output,
            "swiftMarker": swift_marker in output,
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
        "firmwareKind": "production-elf",
    }))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
