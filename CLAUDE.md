# Project Notes for AI Agents

This repo contains QMK keymaps for four keyboards:
- **Kyria Rev4** (Halcyon series) - Split ergonomic keyboard
- **Elora Rev2** (Halcyon series) - Split ergonomic keyboard with number row
- **Keychron Q15 Max** - Ortholinear with Bluetooth/2.4GHz wireless
- **ZSA Planck EZ Glow** - 4x12 ortholinear with per-key RGB

## Swift source of truth

Never author a keymap, semantic, style, or firmware state machine in C.
The module hierarchy is:

1. `SwiftKeymaps/Sources/QMKKeymapKit` and `QMKFirmwareRuntime`: embedded-safe
   framework with no Obbut-specific vocabulary.
2. `SwiftKeymaps/Sources/ObbutKeymaps`: shared Obbut semantics, styles,
   shared layers, actions, configuration, lighting, OS behavior, split state,
   companion support, and pointer engine.
3. The four individual `*Firmware` modules: board composition and
   hardware-specific choices.
4. `QMKFirmwareHost` and `ObbutKeyboardCatalog`: host-only traversal,
   presentation, documentation, and preview aggregation.

QMK directly compiles the annotated firmware declaration as Embedded Swift.
The committed `keymap.c`, `config.h`, and `rules.mk` files are static QMK inputs;
the small C files under `users/` are ABI/platform shims only. No firmware source
generator runs. `qmk-keymap-docs` is host-only and emits keymap-drawer YAML for
`./draw-keymap.sh`.

See `SwiftKeymaps/README.md` for API and customization examples.

## Build Commands

All builds use Docker - no local QMK installation required. Just need Docker Desktop.

### Kyria (Bash)
- `./docker-build.sh kyria-left` / `./docker-build.sh kyria-right` - Compile firmware for each half
- `./docker-build.sh flash-kyria-left` / `./docker-build.sh flash-kyria-right` - Build and flash firmware
- `./docker-build.sh kyria-all` - Compile both halves

### Elora (Bash)
- `./docker-build.sh elora-left` / `./docker-build.sh elora-right` - Compile firmware for each half
- `./docker-build.sh flash-elora-left` / `./docker-build.sh flash-elora-right` - Build and flash firmware
- `./docker-build.sh elora-all` - Compile both halves

### Q15 Max (Bash)
- `./docker-build.sh q15` - Compile Q15 Max firmware
- `./docker-build.sh flash-q15` - Build and flash Q15 Max (requires dfu-util)

### Planck EZ Glow (Bash)
- `./docker-build.sh planck` - Compile Planck EZ Glow firmware
- `./docker-build.sh flash-planck` - Build and flash Planck EZ (requires dfu-util)

### Common
- `./docker-build.sh clean` - Remove build artifacts
- `./draw-keymap.sh` - Regenerate keymap SVGs for all keyboards

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
1. Run `./docker-build.sh flash-kyria-left` or `./docker-build.sh flash-kyria-right`
2. Put the keyboard in bootloader mode when prompted
3. The script auto-detects the `RPI-RP2` drive and copies the firmware

**Manual:**
1. Build firmware: `./docker-build.sh kyria-left` or `./docker-build.sh kyria-right`
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
2. **QWERTY** - Gaming base layer
3. **Lower** - Navigation (arrow keys)
4. **Raise** - Symbols and numpad
5. **Function** - F-keys (F1-F15), RGB controls, Boot keys
6. **Pointer** - Automatically activated Cirque controls, scrolling, sensitivity, and drag lock

## RGB Layer Indicators

The keyboard has per-layer RGB backlighting (all other keys turn off for visibility):

- **Lower layer**: Arrow keys in magenta, Delete/Backspace in orange
- **Raise layer**: Numbers in blue, symbols in yellow
- **Function layer**: F-keys in cyan, RGB controls in green (dark green for decrease), Boot keys in red
- **Pointer layer**: Dim cyan underlay with color-coded controls; dim red underlay while drag lock is active

### Keeping RGB in Sync

RGB presentation is defined by `KeyStyle` values in `ObbutKeymaps`. Keys select
those styles in the shared Swift layers. Firmware lighting, companion rendering,
Xcode previews, and generated SVG YAML all consume the resolved appearance data.

The border styles are defined in `keymap-drawer.yaml` under `svg_style`:
- `rgb-magenta` - Magenta for movement keys
- `rgb-blue` - Blue for number keys
- `rgb-yellow` - Yellow for symbol keys
- `rgb-cyan` - Cyan for F-keys
- `rgb-green` - Green for RGB increase controls
- `rgb-green-dark` - Dark green for RGB decrease controls
- `rgb-red` - Red for Boot keys
- `rgb-orange` - Orange for Delete/Backspace keys

**When changing RGB indicators:** update the relevant key style,
then run the relevant Docker build and `./draw-keymap.sh`.

---

# Elora Rev2 (Halcyon)

## Hardware

- Elora Rev2 (Halcyon series) split keyboard
- Same as Kyria but with an additional number row
- Left half: No module
- Right half: Encoder module
- Each half needs different firmware due to asymmetric modules

## Flashing

**Important:** Each half must be flashed separately. The halves run independent firmware.

### Boot Keys
- **Fn + Esc** → Bootloader for left half
- **Fn + '** → Bootloader for right half

### Flashing Workflow

**Automatic (recommended):**
1. Run `./docker-build.sh flash-elora-left` or `./docker-build.sh flash-elora-right`
2. Put the keyboard in bootloader mode when prompted
3. The script auto-detects the `RPI-RP2` drive and copies the firmware

**Manual:**
1. Build firmware: `./docker-build.sh elora-left` or `./docker-build.sh elora-right`
2. Put keyboard in bootloader mode (appears as `RPI-RP2` drive)
3. Copy the `.uf2` file to the drive (e.g., `elora_rev2_obbut_left.uf2`)

## Physical Layout

```
Row 0 (number): [`]  [1]  [2]  [3]  [4]  [5]       [6]  [7]  [8]  [9]  [0]  [-]
Row 1:          [Tab] [Q]  [W]  [F]  [P]  [B]       [J]  [L]  [U]  [Y]  [;]  [Bksp]
Row 2:          [Esc] [A]  [R]  [S]  [T]  [G]       [M]  [N]  [E]  [I]  [O]  [']
Row 3:          [Sft] [Z]  [X]  [C]  [D]  [V]       [K]  [H]  [,]  [.]  [/]  [Ent]
Thumb:          [Screenshot] [Ctrl] [Cmd] [Aerospace] [Spc]   [Spc] [Raise] [Lower]
```

## Layers

Same typing layers as Kyria (shared code); the Kyria-only Pointer layer is omitted:
1. **Default** - Colemak-DH base layer with number row (`~ 1 2 3 4 5 | 6 7 8 9 0 -`)
2. **QWERTY** - Gaming base layer with number row
3. **Lower** - Navigation (arrow keys), number row transparent
4. **Raise** - Symbols and numpad, number row transparent (direct access to numbers)
5. **Function** - F-keys (F1-F15), RGB controls, Boot keys, number row transparent

## RGB Layer Indicators

Same as Kyria (shared code). See Kyria section above.

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

**Fallback:**
- Hold **Tab** while plugging in USB

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

---

# ZSA Planck EZ Glow

## Hardware

- ZSA Planck EZ Glow - 4x12 ortholinear keyboard
- STM32F303 MCU with stm32-dfu bootloader
- Per-key RGB (IS31FL3737 driver)
- 2u center spacebar (uses `LAYOUT_planck_1x2uC`)

## ZSA Fork

ZSA removed the Planck EZ from mainline QMK. This keyboard uses ZSA's QMK fork via a separate Docker image (`Dockerfile.zsa`). The build uses `make` instead of `qmk compile`.

The keymap is self-contained (not shared with Kyria/Elora) but mirrors the same layout and RGB indicator logic.

**ZSA-specific notes:**
- Keyboard path is `zsa/planck_ez/glow` (not `planck/ez/glow`)
- Uses older RGB keycode names (`RGB_TOG`, `RGB_SAI`, etc.) instead of QMK's newer names (`RM_TOGG`, `RM_SATU`)
- ZSA's `defaults` community module must be manually enabled in `rules.mk` (provides `LED_LEVEL` and `TOGGLE_LAYER_COLOR` keycodes used by keyboard-level code)
- Output filename: `zsa_planck_ez_glow_obbut.bin`

## Flashing

The Planck EZ uses DFU mode for flashing (same mechanism as Q15 Max).

### One-Time Setup (Windows)

Same as Q15 Max - requires dfu-util and WinUSB driver via Zadig. The Planck EZ uses the same STM32 DFU VID:PID (0483:df11).

### Entering DFU Mode

- Press the reset button on the bottom of the keyboard

### Flashing Workflow

**Automatic (recommended):**
```bash
./docker-build.sh flash-planck
```
The script will wait for the keyboard to enter DFU mode.

**Manual:**
1. Build firmware: `./docker-build.sh planck`
2. Put keyboard in DFU mode (reset button on bottom)
3. Flash with: `dfu-util -a 0 -d 0483:df11 -s 0x08000000:leave -D zsa_planck_ez_glow_obbut.bin`

## Physical Layout

```
Row 0: [Tab] [Q] [W] [F] [P] [B] [J] [L] [U] [Y] [;] [Bksp]
Row 1: [Esc] [A] [R] [S] [T] [G] [M] [N] [E] [I] [O] [']
Row 2: [Sft] [Z] [X] [C] [D] [V] [K] [H] [,] [.] [/] [Ent]
Row 3: [PrtSc][Ctrl][Alt][Aero][Cmd]  [Space 2u]  [Raise][Lower][Fn][RAlt][Del]
```

## Layers

Same layout concept as Kyria (reimplemented independently):
1. **Default** - Colemak-DH base layer
2. **QWERTY** - Gaming layer (toggled via Function layer)
3. **Lower** - Navigation (arrow keys), Delete/Backspace
4. **Raise** - Symbols and numpad
5. **Function** - F-keys (F1-F15), RGB controls, Boot keys, QWERTY toggle

## RGB Layer Indicators

The Planck consumes the same Swift styles and generated lighting path as
the other boards. See Kyria above for the color mapping.
