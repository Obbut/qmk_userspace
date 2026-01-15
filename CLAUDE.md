# Project Notes for AI Agents

## Keymap Synchronization

This project has two keymap definitions that must stay in sync:

1. **`keyboards/splitkb/halcyon/kyria/keymaps/obbut/keymap.c`** - The actual QMK keymap (compiled into firmware)
2. **`keymap.yaml`** - Manual YAML for keymap-drawer visualization

**When changing the keymap:**
1. Update `keymap.c` with the firmware changes
2. Update `keymap.yaml` to match (this is manually maintained, not auto-generated)
3. Run `./draw-keymap.sh` (or `./build.ps1 draw` on Windows) to regenerate `images/*.svg`
4. Commit all files together

## Build Commands

All builds use Docker - no local QMK installation required. Just need Docker Desktop.

### Bash (macOS/Linux/Git Bash on Windows)
- `./docker-build.sh left` / `./docker-build.sh right` - Compile firmware for each half
- `./docker-build.sh flash-left` / `./docker-build.sh flash-right` - Build and flash firmware
- `./docker-build.sh all` - Compile both halves
- `./docker-build.sh clean` - Remove build artifacts
- `./draw-keymap.sh` - Regenerate keymap SVGs

### PowerShell (Windows)
- `./build.ps1 left` / `./build.ps1 right` - Compile firmware for each half
- `./build.ps1 flash-left` / `./build.ps1 flash-right` - Build and flash firmware
- `./build.ps1 draw` - Regenerate keymap SVGs

### Makefile (macOS with native QMK)
- `make left` / `make right` - Compile firmware (requires local QMK CLI)
- `make flash-left` / `make flash-right` - Flash firmware
- `make draw` - Regenerate keymap SVGs

## Setup

**Only requirement: Docker Desktop**

The build scripts automatically:
1. Build a Docker image with QMK firmware and toolchain (first run takes ~2-3 minutes)
2. Mount this userspace as an overlay
3. Compile and output `.uf2` files to this directory

No need to install QMK CLI, Python, or ARM toolchains locally.

## Flashing

**Important:** Each half must be flashed separately. The halves run independent firmware.

### Boot Keys
- **Fn + Esc** → Bootloader for left half
- **Fn + '** → Bootloader for right half

### Flashing Workflow

**Automatic (recommended):**
1. Run `./docker-build.sh flash-left` or `./docker-build.sh flash-right` (bash)
   - Or `./build.ps1 flash-left` / `./build.ps1 flash-right` (PowerShell)
2. Put the keyboard in bootloader mode when prompted
3. The script auto-detects the `RPI-RP2` drive and copies the firmware

**Manual:**
1. Build firmware: `./docker-build.sh left` or `./docker-build.sh right`
2. Put keyboard in bootloader mode (appears as `RPI-RP2` drive)
3. Copy the `.uf2` file to the drive (e.g., `kyria_rev4_obbut_left_cirque.uf2`)

**Tip:** You can start the flash command before the keyboard is in bootloader mode. The script will wait up to 60 seconds for the drive to appear.

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

The keyboard has per-layer RGB backlighting (all other keys turn off for visibility):

- **Lower layer**: Arrow keys in magenta, Delete/Backspace in orange
- **Raise layer**: Numbers in blue, symbols in yellow
- **Function layer**: F-keys in cyan, RGB controls in green (dark green for decrease), Boot keys in red

### Keeping RGB in Sync

RGB indicators are defined in **two places** that must stay in sync:

1. **`keymap.c`** - The actual RGB code in `rgb_matrix_indicators_advanced_user()`
2. **`keymap.yaml`** - Border colors via `type` field on keys (e.g., `{t: LEFT, type: rgb-magenta}`)

The border styles are defined in `keymap-drawer.yaml` under `svg_style`:
- `rgb-magenta` - Magenta for movement keys
- `rgb-blue` - Blue for number keys
- `rgb-yellow` - Yellow for symbol keys
- `rgb-cyan` - Cyan for F-keys
- `rgb-green` - Green for RGB increase controls
- `rgb-green-dark` - Dark green for RGB decrease controls
- `rgb-red` - Red for Boot keys
- `rgb-orange` - Orange for Delete/Backspace keys

**When changing RGB indicators:**
1. Update the logic in `keymap.c` (`rgb_matrix_indicators_advanced_user`)
2. Update the `type` fields in `keymap.yaml` for affected keys
3. Run `./docker-build.sh` then `./draw-keymap.sh` (or `./build.ps1 draw` on Windows) to regenerate the SVGs
