# Kyria left crash: process-stack exhaustion

## Conclusion

The Swift Kyria left firmware exhausts the default 2 KiB ChibiOS process
stack. The stack bottom guard is overwritten before the event loop stalls; the
RP2040 watchdog then resets the board. This is not a USB-only failure: the
event-loop heartbeat stops and the hardware watchdog recovers the MCU.

## Evidence

- The original fault left the USB interfaces enumerated but Raw HID stopped
  replying. The left RGB animation froze while the right half continued.
- Diagnostic build `2a1b9398`, using the default 2 KiB process stack, retained:
  `reason=watchdog`, `phase=idle`, `flags=0x1c`, `failures=2`, `uptime=6`,
  `SP=0x20040bd0`, and `stackFree=0`. Flag `0x1c` means deep diagnostics,
  valid stack high-water data, and a damaged bottom guard.
- Its map places the process stack at `0x20040400..0x20040c00` (2 KiB).
- A 4 KiB process-stack control could not link because the RP2040 ChibiOS
  linker reserves a 4 KiB scratch bank for the process stack, exception stack,
  and time-critical RAM code.
- A 3 KiB process stack with a 512-byte exception stack linked. Diagnostic
  build `3378d482` remained responsive during several minutes of repeated
  typing and Cirque use. Live protocol requests continued to receive replies
  and no crash report was created.
- Restoring the 2 KiB process stack in build `82c60410` reproduced the failure
  and reached UF2 after three consecutive failed boots.
- A subsequent 2 KiB collector build also exhausted the stack before USB was
  queryable. The recovered retained stack state again had `flags=0x1c` and
  `stackFree=0`.

This A/B/A result changes only the available process-stack space and is enough
to establish stack exhaustion as the cause. Subsystem bypass builds and the
older-firmware/right-master controls are therefore unnecessary for this fault.

## Recovery-policy issues found during collection

The live investigation also exposed two diagnostics-policy defects that are
fixed with the crash-recovery implementation:

- a different firmware build must be allowed to boot and expose a retained
  three-failure report;
- an unacknowledged crash report must not be overwritten by a later manual
  reset, and its stored failure count must not replace the live boot-loop
  counter after ten healthy seconds.

## Deliberate recovery validation

A 3 KiB diagnostic build with `OBBUT_INJECT_HARDFAULT=1` rebooted after each
fault and entered RP2040 UF2 after the third failure. A different stable image
then retrieved the retained record:

`reason=HardFault`, `phase=Swift post-init`, `flags=0x1b`, `failures=3`,
`PC=0x10001638`, `LR=0x10001639`, `SP=0x20040dc0`, `stackFree=2928`.

The matching ELF symbolicates both PC and LR to the intentional `udf` in
`obbut_crash_recovery_initialize_stack`. Flags `0x1b` confirm valid fault
registers, a valid stack high-water measurement, an intact bottom guard, and
deep diagnostics.

## Fix constraint

The proven configuration is a `0xC00` (3 KiB) process stack and a `0x200`
(512-byte) exception stack. The firmware fix should apply that configuration
to the Kyria and remain separate from the diagnostics commit.
