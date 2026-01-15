# Project Notes for AI Agents

This repo contains QMK keymaps for two keyboards:
- **Kyria Rev4** (Halcyon series) - Split ergonomic keyboard
- **Keychron Q15 Max** - Ortholinear with Bluetooth/2.4GHz wireless

## Keymap Synchronization

Each keyboard has keymap definitions that must stay in sync:

### Kyria
1. **`keyboards/splitkb/halcyon/kyria/keymaps/obbut/keymap.c`** - QMK firmware keymap
2. **`keymap-kyria.yaml`** - Manual YAML for keymap-drawer visualization

### Q15 Max
1. **`keyboards/keychron/q15_max/ansi_encoder/keymaps/obbut/keymap.c`** - QMK firmware keymap
2. **`keymap-q15.yaml`** - Manual YAML for keymap-drawer visualization

**When changing a keymap:**
1. Update `keymap.c` with the firmware changes
2. Update the corresponding `.yaml` file to match
3. Run `./draw-keymap.sh` to regenerate `images/*.svg`
4. Commit all files together

## Build Commands

All builds use Docker - no local QMK installation required. Just need Docker Desktop.

### Kyria (Bash)
- `./docker-build.sh left` / `./docker-build.sh right` - Compile firmware for each half
- `./docker-build.sh flash-left` / `./docker-build.sh flash-right` - Build and flash firmware
- `./docker-build.sh all` - Compile both halves

### Q15 Max (Bash)
- `./docker-build.sh q15` - Compile Q15 Max firmware
- `./docker-build.sh flash-q15` - Build and flash Q15 Max (requires dfu-util)

### Common
- `./docker-build.sh clean` - Remove build artifacts
- `./draw-keymap.sh` - Regenerate keymap SVGs for both keyboards

### PowerShell (Windows)
- `./build.ps1 left` / `./build.ps1 right` - Compile Kyria firmware
- `./build.ps1 flash-left` / `./build.ps1 flash-right` - Build and flash Kyria
- `./build.ps1 draw` - Regenerate keymap SVGs

## Setup

**Only requirement: Docker Desktop**

The build scripts automatically:
1. Build Docker images with QMK firmware and toolchain (first run takes ~2-3 minutes)
2. Mount this userspace as an overlay
3. Compile and output firmware files to this directory

No need to install QMK CLI, Python, or ARM toolchains locally.

---

# Kyria Rev4 (Halcyon)

## Hardware

- Kyria Rev4 (Halcyon series) split keyboard
- Left half: Cirque trackpad module
- Right half: Encoder module
- Each half needs different firmware due to asymmetric modules

## Flashing

**Important:** Each half must be flashed separately. The halves run independent firmware.

### Boot Keys
- **Fn + Esc** → Bootloader for left half
- **Fn + '** → Bootloader for right half

### Flashing Workflow

**Automatic (recommended):**
1. Run `./docker-build.sh flash-left` or `./docker-build.sh flash-right`
2. Put the keyboard in bootloader mode when prompted
3. The script auto-detects the `RPI-RP2` drive and copies the firmware

**Manual:**
1. Build firmware: `./docker-build.sh left` or `./docker-build.sh right`
2. Put keyboard in bootloader mode (appears as `RPI-RP2` drive)
3. Copy the `.uf2` file to the drive (e.g., `kyria_rev4_obbut_left_cirque.uf2`)

**Tip:** You can start the flash command before the keyboard is in bootloader mode. The script will wait up to 60 seconds for the drive to appear.

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
2. **`keymap-kyria.yaml`** - Border colors via `type` field on keys (e.g., `{t: LEFT, type: rgb-magenta}`)

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
2. Update the `type` fields in `keymap-kyria.yaml` for affected keys
3. Run `./docker-build.sh` then `./draw-keymap.sh` to regenerate the SVGs

---

# Keychron Q15 Max

## Hardware

- Keychron Q15 Max ortholinear keyboard
- 64 keys + 2 rotary encoders
- Wireless: Bluetooth 5.1 (3 devices) + 2.4GHz
- STM32F401 MCU with DFU bootloader

## Flashing

The Q15 Max uses DFU (Device Firmware Upgrade) mode for flashing.

### One-Time Setup (Windows)

Before first flash, install:
1. **dfu-util**: Download from https://dfu-util.sourceforge.net/releases/ and add to PATH
   - Or install QMK MSYS which includes dfu-util
2. **WinUSB driver**:
   - Put Q15 in DFU mode (see below)
   - Run [Zadig](https://zadig.akeo.ie/)
   - Select "STM32 BOOTLOADER" (VID: 0483, PID: df11)
   - Install "WinUSB" driver

### Entering DFU Mode

**With custom firmware (Fn + Tab):**
- Press **Fn + Tab** to enter DFU mode directly

**With stock firmware or as fallback:**
1. Set the mode switch to "Cable" (wired mode)
2. Unplug the keyboard
3. Hold **Esc** while plugging in USB
4. Release after the keyboard enters DFU mode

### Flashing Workflow

**Automatic (recommended):**
```bash
./docker-build.sh flash-q15
```
The script will wait for the keyboard to enter DFU mode.

**Manual:**
1. Build firmware: `./docker-build.sh q15`
2. Put keyboard in DFU mode
3. Flash with: `dfu-util -a 0 -d 0483:df11 -s 0x08000000:leave -D keychron_q15_max_ansi_encoder_obbut.bin`

## Physical Layout

```
Row 0: [Enc] [1] [2] [3] [4] [5] [6] [7] [8] [9] [0] [-] [⌫] [Enc]
Row 1: [Tab] [Q] [W] [E] [R] [T] [Y] [U] [I] [O] [P] [{] [}] [|]
Row 2: [Esc] [A] [S] [D] [F] [G] [H] [J] [K] [L] [:] ['] [Enter 2u]
Row 3: [Shft][Z] [X] [C] [V] [B] [N] [M] [<] [>] [?] [Shft][↑][Del]
Row 4: [   ][   ][Ctrl][Opt][Cmd 1.25u][Spc 1.75u][Fn1][Fn2][←][↓][→]
```

## Layers

1. **MAC_BASE** - macOS QWERTY base layer
2. **WIN_BASE** - Windows QWERTY base layer
3. **MAC_FN** (Fn1) - macOS function layer (media, RGB, Bluetooth)
4. **WIN_FN** (Fn1) - Windows function layer (media, RGB, Bluetooth)
5. **COM_FN** (Fn2) - Common function layer (F-keys, battery level)

## Keychron-Specific Features

Bluetooth/Wireless keycodes (on function layers):
- `BT_HST1`, `BT_HST2`, `BT_HST3` - Switch Bluetooth device (Fn + 1/2/3)
- `P2P4G` - Switch to 2.4GHz wireless mode (Fn + 4)
- `BAT_LVL` - Show battery level on RGB LEDs (Fn + B)

## Encoder Behavior

- **Base layers**: Volume control (rotate)
- **Function layers**: RGB brightness (rotate)
