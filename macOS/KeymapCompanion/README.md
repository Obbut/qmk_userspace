# Keymap Companion

Keymap Companion is a native SwiftUI utility for macOS 27. It discovers the Raw HID interface exposed by this userspace's Kyria and Elora firmware, shows the effective keymap, and follows momentary or toggled layers in realtime.

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

Once a flashed board enumerates, the app finds QMK's vendor usage page `0xFF60` and usage `0x61`, opens the matching endpoint, and sends a state request. The keyboard identity comes from the validated response, so the host does not depend on hardcoded USB vendor or product IDs.

## Protocol

Every Raw HID report is exactly 32 bytes and starts with `KMAP` plus protocol version `1`.

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
| 24 | 8 | Reserved for future versions |

The app combines both layer masks and resolves transparent keys through the complete active stack. For example, a transparent key on Lower still displays its QWERTY mapping when QWERTY is toggled underneath it.

Firmware sends only after a host handshake and only when state changes. The callback marks state dirty; the actual Raw HID write is throttled and performed from QMK's housekeeping task on the USB master.

## Extension point for OS-driven keymap features

The HID transport is deliberately bidirectional and versioned. Future work such as Aerospace workspace state can add a host-to-keyboard message type and a capability bit without coupling workspace integration to the layer monitor. Keep OS integrations above `KeymapProtocol` in the app, then translate their state into compact protocol packets; keep rendering or RGB behavior in the shared `users/obbut_halcyon` firmware layer so Kyria and Elora remain synchronized.
