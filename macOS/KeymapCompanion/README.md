# Keymap Companion for macOS

Keymap Companion is a native SwiftUI utility for all four Swift-authored
firmwares in this repository. It discovers QMK Raw HID devices, downloads the
compiled keymap, resolves domain-owned semantics and styles, follows layer
changes in realtime, and renders the result with the same
`QMKKeymapRenderer` used by the Xcode keymap previews.

The app uses protocol v4 only. There is intentionally no legacy decoder or
compatibility mode. The protocol carries a stable layout ID, keymap and catalog
fingerprints, arbitrary layers, arbitrary matrix placements, and zero or more
encoders. Unknown catalog IDs remain visible as diagnostics while ordinary QMK
keycodes continue to render.

## Open in Xcode

Open `KeymapCompanion.xcodeproj`, choose the `KeymapCompanion` scheme and My
Mac, then Run. The local package dependency graph includes `SwiftKeymaps`, so
the four firmware modules, `ObbutKeymaps`, and renderer are editable in
the same Xcode workspace.

Keymap previews are deliberately independent of this app. Open
`../../SwiftKeymaps/Package.swift`, select My Mac and the matching firmware
scheme, then open that firmware's Swift source. Its `#Preview` declaration lives
in the same file as the keymap.

The generated preview starts with an all-layers overview and includes an
interactive layer selector. It renders the real authored firmware definition,
not a preview-only model.

Command-line validation:

```sh
cd macOS/KeymapCompanion
xcodebuild \
  -project KeymapCompanion.xcodeproj \
  -scheme KeymapCompanion \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

The project is generated from `project.yml`. Regenerate after project-structure
changes with `xcodegen generate --spec project.yml`.

The app is intentionally not sandboxed because it opens QMK's vendor-defined
IOHID interface directly. Hardened Runtime remains enabled.

## Shared implementation

`Shared/KeymapCompanionCore` owns the `@MainActor @Observable` application
model and protocol transfer state. macOS injects IOHID transport and Windows
injects its native SetupAPI transport. Both consume `ObbutKeyboardCatalog` and
the same domain-resolved document model.

`Shared/KeymapProtocol` is compiled twice from the same Swift source: once for
the host apps and once with Embedded Swift for firmware. Swift owns packet
layout, transfer pagination, fingerprints, and state. Generated C and the small
QMK platform shim expose ABI facts such as matrix entries, timers, Raw HID, and
RGB persistence; they contain no authored keymap or protocol semantics.

All Raw HID reports are 32 bytes and begin with `KMAP` plus version `4`.
Metadata reports identify the layout and catalog fingerprints; chunk reports
stream variable-sized layer, matrix, and encoder entries. Corrupt or reordered
transfers are rejected by the fingerprint check.

## Firmware

Build companion-enabled firmware through the existing Docker interface:

```sh
./docker-build.sh kyria-all
./docker-build.sh elora-all
./docker-build.sh q15
./docker-build.sh planck
```

The build runs `qmk-keymapc` first, then compiles the protocol runtime,
`ObbutKeymaps`, and the selected board module with Swift 6.3.3 for the QMK MCU
target before linking the normal firmware artifact.
