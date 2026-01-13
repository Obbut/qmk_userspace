# QMK Userspace - Kyria Rev4 (Halcyon)

Personal QMK firmware for Kyria Rev4 (Halcyon series) with asymmetric modules:
- **Left half**: Cirque trackpad
- **Right half**: Encoder module

## Build Commands

```bash
make all          # Build both firmware files
make left         # Build Cirque trackpad firmware (left half)
make right        # Build encoder firmware (right half)
make flash-left   # Build and flash left half
make flash-right  # Build and flash right half
make clean        # Remove compiled firmware files
```

## Flashing

1. Put the keyboard half into bootloader mode (double-tap reset button)
2. Run the appropriate flash command or copy the .uf2 file to the mounted drive:
   - `kyria_rev4_obbut_cirque.uf2` → Left half (Cirque trackpad)
   - `kyria_rev4_obbut_encoder.uf2` → Right half (Encoder)

## Keymap

4-layer Colemak-DH layout:
- **Default**: Colemak-DH base layer
- **Lower**: Navigation (arrows, delete)
- **Raise**: Symbols and numpad
- **Function**: F-keys (F1-F15) and RGB controls

## Attribution

This repository contains files from [splitkb/qmk_userspace](https://github.com/splitkb/qmk_userspace) (halcyon-qmk branch).

### Copied Files

The following files were copied from splitkb/qmk_userspace at revision [`f3800fa54450d2a51c2e14f04aa254fd94b3ae02`](https://github.com/splitkb/qmk_userspace/tree/f3800fa54450d2a51c2e14f04aa254fd94b3ae02):

| Path | Description |
|------|-------------|
| `LICENSE` | GPL v2 license |
| `keyboards/splitkb/halcyon/kyria/` | Kyria Rev4 Halcyon keyboard definition |
| `users/halcyon_modules/` | Halcyon module support code (Cirque, encoder, display) |
| `.github/workflows/build_binaries.yaml` | GitHub Actions build workflow |

## License

This project is licensed under the GNU General Public License v2.0 - see the [LICENSE](LICENSE) file for details.

The Halcyon keyboard definitions and module support code are copyright splitkb.com and licensed under GPL-2.0-or-later.
