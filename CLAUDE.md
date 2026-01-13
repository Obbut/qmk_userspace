# Project Notes for AI Agents

## Keymap Synchronization

This project has two keymap definitions that must stay in sync:

1. **`keyboards/splitkb/halcyon/kyria/keymaps/obbut/keymap.c`** - The actual QMK keymap (compiled into firmware)
2. **`keymap.yaml`** - Manual YAML for keymap-drawer visualization

**When changing the keymap:**
1. Update `keymap.c` with the firmware changes
2. Update `keymap.yaml` to match (this is manually maintained, not auto-generated)
3. Run `make draw` to regenerate `images/keymap.svg`
4. Commit all three files together

## Build Commands

- `make left` / `make right` - Compile firmware for each half
- `make flash-left` / `make flash-right` - Flash firmware
- `make draw` - Regenerate keymap SVG (requires Docker)

## Hardware

- Kyria Rev4 (Halcyon series) split keyboard
- Left half: Cirque trackpad module
- Right half: Encoder module
- Each half needs different firmware due to asymmetric modules
