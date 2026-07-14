# Keymap Companion

Keymap Companion is a native SwiftUI utility for macOS 27. It discovers the Raw HID interface exposed by this userspace's Kyria and Elora firmware, downloads the complete compiled keymap and encoder map, and follows momentary or toggled layers in realtime. The connected firmware is the source of truth for keycodes, semantic overrides, and RGB-inspired styles; the app retains only physical board geometry and generic QMK keycode formatting.

The app has both a normal `WindowGroup` and a `MenuBarExtra`. Closing the main window leaves the same process-level `AppModel` and HID monitor running. Use the keyboard item in the menu bar to reopen the window, retry discovery, or quit.

## Requirements

- macOS 27
- Xcode 27 with Swift 6
- XcodeGen only when regenerating the checked-in Xcode project
- Docker/OrbStack for QMK firmware builds
- A Kyria Rev4 or Elora Rev2 connected over USB

## Build and run the app

Open `KeymapCompanion.xcodeproj`, select the `KeymapCompanion` scheme and My Mac, then run it. The target uses Swift 6 language mode, complete strict-concurrency checking, Main Actor default isolation, and warnings as errors.

From the command line:

```sh
cd macOS/KeymapCompanion
xcodebuild \
  -project KeymapCompanion.xcodeproj \
  -scheme KeymapCompanion \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

The project is generated from `project.yml`. After changing targets or build settings, regenerate it with:

```sh
cd macOS/KeymapCompanion
xcodegen generate --spec project.yml
```

The app is intentionally not sandboxed because it opens the QMK vendor-defined IOHID interface directly. Hardened Runtime remains enabled.

## Build and flash companion-enabled firmware

Raw HID is compiled into all four Elora/Kyria half variants. Flash both halves so either side can become the USB master:

```sh
./docker-build.sh kyria-all
./docker-build.sh elora-all
```

Then flash each half with the existing commands:

```sh
./docker-build.sh flash-kyria-left
./docker-build.sh flash-kyria-right
./docker-build.sh flash-elora-left
./docker-build.sh flash-elora-right
```

Once a flashed board enumerates, the app finds QMK's vendor usage page `0xFF60` and usage `0x61`, opens the matching endpoint, downloads and fingerprint-validates the keymap, and then requests current state. The keyboard identity comes from the validated responses, so the host does not depend on hardcoded USB vendor or product IDs.

## Protocol

Every Raw HID report is exactly 32 bytes and starts with `KMAP` plus protocol version `3`.

| Message type | Value | Direction | Purpose |
|---|---:|---|---|
| Get state | `1` | Host → firmware | Request immediate layer state |
| State | `2` | Firmware → host | Current layer masks and capabilities |
| Get keymap info | `3` | Host → firmware | Begin a complete keymap transfer |
| Keymap info | `4` | Firmware → host | Matrix and encoder dimensions, entry count, and fingerprint |
| Get keymap chunk | `5` | Host → firmware | Request entries beginning at a 16-bit offset |
| Keymap chunk | `6` | Firmware → host | Return up to five consecutive entries |
| Set RGB settings | `7` | Host → firmware | Persist a complete RGB Matrix configuration |

### State packet

| Offset | Size | State packet field |
|---:|---:|---|
| 0 | 4 | ASCII magic `KMAP` |
| 4 | 1 | Protocol version |
| 5 | 1 | Message type: `1` request, `2` state |
| 6 | 1 | Keyboard: `1` Kyria, `2` Elora |
| 7 | 1 | Highest active layer |
| 8 | 4 | QMK `layer_state`, little-endian |
| 12 | 4 | QMK `default_layer_state`, little-endian |
| 16 | 4 | Packet sequence, little-endian |
| 20 | 4 | Capability flags, little-endian |
| 24 | 1 | Stable companion RGB effect identifier |
| 25 | 1 | RGB hue |
| 26 | 1 | RGB saturation |
| 27 | 1 | RGB brightness |
| 28 | 1 | RGB enabled flag |
| 29 | 1 | RGB animation speed |
| 30 | 1 | Number of available RGB effects |
| 31 | 1 | Reserved |

Capability bit `0` advertises realtime layer state. Bit `1` advertises firmware keymap reads. Bit `2` advertises explicit RGB Matrix settings.

### Keymap info packet

| Offset | Size | Field |
|---:|---:|---|
| 0 | 4 | ASCII magic `KMAP` |
| 4 | 1 | Protocol version `3` |
| 5 | 1 | Message type `4` |
| 6 | 1 | Keyboard: `1` Kyria, `2` Elora |
| 7 | 1 | Layer count |
| 8 | 1 | Matrix row count |
| 9 | 1 | Matrix column count |
| 10 | 1 | Entry size: `4` bytes |
| 11 | 1 | Entries per chunk: `5` |
| 12 | 4 | FNV-1a keymap fingerprint, little-endian |
| 16 | 2 | Total entry count, little-endian |
| 18 | 1 | Encoder count |
| 19 | 1 | Encoder direction count: `2` |
| 20 | 12 | Reserved for future versions |

The fingerprint covers keyboard kind, matrix and encoder dimensions, and every encoded entry. The app rejects an incomplete, reordered, or corrupted transfer.

### Keymap chunk packet

The host writes the desired 16-bit start index at offsets `6...7` of a Get keymap chunk request. The firmware returns:

| Offset | Size | Field |
|---:|---:|---|
| 0 | 4 | ASCII magic `KMAP` |
| 4 | 1 | Protocol version `3` |
| 5 | 1 | Message type `6` |
| 6 | 1 | Keyboard kind |
| 7 | 1 | Entry count in this chunk |
| 8 | 2 | Start index, little-endian |
| 10 | 2 | Total entry count, little-endian |
| 12 | 20 | Up to five four-byte entries |

Each entry contains a 16-bit compiled QMK keycode, a one-byte semantic override, and a one-byte visual style. The complete layer-major matrix comes first, followed by counter-clockwise and clockwise encoder entries for each layer. The encoder push switch remains a normal matrix entry (`r9c0` on Kyria and `r11c0` on Elora). Semantic overrides preserve names such as `Screenshot` and `Aerospace` that cannot be recovered from the compiled keycode after C preprocessing.

The app maps the downloaded matrix coordinates onto its physical Kyria or Elora geometry, combines both layer masks, and resolves transparent keys through the complete active stack. For example, a transparent key on Lower still displays its firmware-provided QWERTY mapping when QWERTY is toggled underneath it.

Firmware sends keymap metadata and chunks only in response to host requests. After that handshake, state notifications are sent when layer or RGB state changes. Callbacks mark state dirty; the actual state write is throttled and performed from QMK's housekeeping task on the USB master.

The RGB settings popover is shown only when capability bit `2` is present.

An RGB settings request uses message type `7`. Byte `6` is the enabled flag, byte `7` is the stable effect identifier, and bytes `8` through `11` contain hue, saturation, brightness, and speed. Firmware maps the stable identifiers to QMK's build-dependent effect enum, applies the complete configuration, persists it once, and immediately echoes the resulting state.

## Extension point for OS-driven keymap features

The HID transport is deliberately bidirectional and versioned. Future work such as Aerospace workspace state can add a host-to-keyboard message type and a capability bit without coupling workspace integration to the layer monitor. Keep OS integrations above `KeymapProtocol` in the app, then translate their state into compact protocol packets; keep rendering or RGB behavior in the shared `users/obbut_halcyon` firmware layer so Kyria and Elora remain synchronized.
