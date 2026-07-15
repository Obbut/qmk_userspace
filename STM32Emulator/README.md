# STM32 production-ELF emulator

This harness executes the exact Planck EZ Glow and Keychron Q15 Max ELF files
produced by their normal QMK builds. It uses pinned Renode 1.16.1 and does not
compile an emulator-only firmware variant.

Renode does not model STM32 USB device controllers, the Keychron wireless
coprocessor, or either keyboard's external RGB controller. The platform scripts
therefore terminate those hardware boundaries while retaining the real QMK
loop, matrix scanning, Embedded Swift runtime, firmware hooks, layer logic,
metadata, encoder lookup, and RGB policy in the executed ARM binary.

Run both production builds and boot checks with:

```sh
./docker-build.sh test-stm32-emulators
```
