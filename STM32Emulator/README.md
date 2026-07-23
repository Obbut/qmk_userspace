# STM32 production-ELF emulator

This harness executes the exact Planck EZ Glow and Keychron Q15 Max ELF files
produced by their normal QMK builds. It uses pinned Renode 1.16.1 and does not
compile an emulator-only firmware variant.

Renode does not model STM32 USB device controllers, the Keychron wireless
coprocessor, or either keyboard's external RGB controller. The platform scripts
therefore terminate those hardware boundaries while retaining the real QMK
loop, matrix scanning, Embedded Swift runtime, firmware hooks, layer logic,
metadata, encoder lookup, and RGB policy in the executed ARM binary. After
boot, it calls every exported matrix and encoder lookup in that same ELF and
compares the result with a committed snapshot independently resolved by the
host model. It also traverses QMK's own matrix/encoder resolution boundary,
runs ordinary key events through the complete feature tuple, checks Planck's
tri-layer transitions, executes RGB indicator policy, and requests protocol-v5
metadata plus the first and last keymap chunks through the board's real Raw HID
receive entry point.

Run both production builds and boot checks with:

```sh
./docker-build.sh test-stm32-emulators
```

Refresh a snapshot after an intentional keymap change with:

```sh
swift run --package-path SwiftKeymaps qmk-keymap-docs \
    --keyboard planck --emulator-fixture
```

The snapshot is test data only. Firmware builds never execute the exporter and
Renode always loads the ordinary production ELF.
