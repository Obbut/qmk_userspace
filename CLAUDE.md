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

## Flashing

**Important:** Each half must be flashed separately. The halves run independent firmware.

### Boot Keys
- **Fn + Esc** → Bootloader for left half
- **Fn + '** → Bootloader for right half

### Flashing Workflow
1. Run `make flash-left` or `make flash-right` - the command will wait for the bootloader
2. Put the keyboard half into bootloader mode (the command can be started first!)
3. The flash will complete automatically when the drive appears
4. Repeat for the other half if needed

**Tip:** You can start the flash command before the keyboard is in bootloader mode. QMK will wait for the drive to appear, so you have time to press the boot key combo after starting the command.

## Hardware

- Kyria Rev4 (Halcyon series) split keyboard
- Left half: Cirque trackpad module
- Right half: Encoder module
- Each half needs different firmware due to asymmetric modules

## Physical Keycaps

The keycaps are labeled as follows (useful for discussing layout changes):

### Left Half
```
Row 1: [Tab⌅]  [Q]  [W]  [F]  [P]  [B]
Row 2: [Esc⎋]  [A]  [R]  [S]  [T]  [G]
Row 3: [Shift⇧] [Z]  [X]  [C]  [D]  [V]     Thumb: [Option⌥] [Heart♥]
Row 4 (thumb):  [Circle●] [Control⌃] [Command⌘] [Triangle▲] [Blank]
```

### Right Half
```
Row 1:                        [J]  [L]  [U]  [Y]  [;:]  [Backspace⌫]
Row 2:                        [M]  [N]  [E]  [I]  [O]   ['"]
Row 3: Thumb: [FN] [CODE]     [K]  [H]  [,<] [.>] [/?]  [Return↵]
Row 4 (thumb):  [META] [Blank] [Raise↑] [Lower↓] [Square■]
```

### Key Reference

When discussing keys, you can refer to them by their keycap label:
- **Heart** = Left thumb row 3, inner position
- **Option** = Left thumb row 3, outer position
- **Triangle** = Left thumb row 4, 4th from left
- **Circle** = Left thumb row 4, outermost
- **FN** = Right thumb row 3, outer position
- **CODE** = Right thumb row 3, inner position
- **META** = Right thumb row 4, innermost
- **Square** = Right thumb row 4, outermost
- **Raise↑** = Right thumb row 4, 3rd from left
- **Lower↓** = Right thumb row 4, 4th from left

## Layers

1. **Default** - Colemak-DH base layer
2. **Lower** - Navigation (arrow keys)
3. **Raise** - Symbols and numpad
4. **Function** - F-keys (F1-F15), RGB controls, Boot keys

## RGB Layer Indicators

The keyboard has per-layer RGB backlighting:
- **Lower layer**: Arrow keys highlighted in magenta
- **Raise layer**: Number keys in blue, symbol keys in yellow
- All other keys turn off on these layers for visibility
