# Swift QMK keymaps

The declarations in this package are the firmware source of truth. QMK invokes
Embedded Swift directly, compiles the selected annotated firmware enum, and
links that object into the keyboard ELF. There is no generated C keymap and no
host artifact-generation step in a firmware build.

## Firmware API

An individual firmware module contains board composition and hardware policy:

```swift
import ObbutKeymaps
import QMKFirmwareRuntime
import QMKKeymapKit

@QMKFirmware
public enum KyriaFirmware {
    public typealias LayerID = ObbutLayer

    public static let id: FirmwareID = "com.obbut.kyria-rev4"
    public static let layout = KyriaRev4Layout()
    public static let outputName: StaticString = "kyria_rev4_obbut"

    public static var keymap: some KeymapDefinition {
        SharedHalcyonLayers(layout: .kyria)
        KyriaPointerLayer()
        ObbutEncoder.halcyon(includesPointerLayer: true)
    }

    public static var features: some FirmwareFeatureSet {
        ObbutKeymapCompanion()
        ObbutWindowsOverrides()
        ObbutLayerLighting()
        ObbutSplitSynchronization()
        KyriaPointerFeature()
    }
}

#if canImport(SwiftUI) && !hasFeature(Embedded)
import QMKKeymapRenderer
import SwiftUI

#Preview("Kyria") {
    KeymapPreviewView(KyriaFirmware.self)
}
#endif
```

`@QMKFirmware` adds the `QMKFirmware` conformance and attaches the `@Keymap`
result builder to `keymap`. It diagnoses missing policy members, duplicate or
non-static keymaps, redundant conformance, and a redundant explicit `@Keymap`.
The macro only emits Swift syntax in compiler memory; it never writes source,
configuration, lookup tables, or firmware inputs.

Every firmware has an associated `LayerID` type. A firmware made from direct
layer declarations can let the macro generate its nested enum:

```swift
@QMKFirmware
public enum PlanckFirmware {
    public static var keymap: some KeymapDefinition {
        Layer(name: "Default") {
            // ...
            Row(/* ... */, .momentary(LayerID.function), /* ... */)
        }

        Layer(name: "Lower", showsHUD: true) {
            // ...
        }

        Layer(name: "Function", showsHUD: true) {
            // ...
        }
    }
}
```

The declaration above receives a nested `LayerID: UInt8, FirmwareLayerID` with
`defaultLayer`, `lower`, and `function` cases in declaration order. Swift
keywords receive a `Layer` suffix. The generated enum is public, so projects
can add their own protocol conformances in extensions.

Boards that intentionally share layer numbering provide the associated type
explicitly, which suppresses generation:

```swift
public enum SharedLayerID: UInt8, FirmwareLayerID {
    case base
    case lower
    case function
}

@QMKFirmware
public enum FirstFirmware {
    public typealias LayerID = SharedLayerID

    public static var keymap: some KeymapDefinition {
        Layer(LayerID.base, name: "Default") { /* ... */ }
        Layer(LayerID.lower, name: "Lower") { /* ... */ }
        Layer(LayerID.function, name: "Function") { /* ... */ }
    }
}
```

Rows and reusable static components remain readable:

```swift
Row(.tab, .q, .w, .e, .r, .t, .y, .u, .i, .o, .p, .backspace)

Row {
    Repeat(.transparent, count: 14)
    .grave.style(.symbol)
    .exclamation.style(.symbol)
    .at.style(.symbol)
    FunctionKeys(1...12, style: .function)
}
```

The builder produces nested generic nodes. Firmware lookup does not construct
`[Key]`, allocate, reflect over values, or erase the keymap behind an
existential. QMK keycodes are their real `UInt16` ABI values:

```swift
.qmk(.brightnessDown, legend: "Brightness −")
.qmk(.triLayerUpper, legend: "Raise")
```

## Executable features

Features own their state and QMK behavior in Swift:

```swift
public protocol FirmwareFeature: Sendable {
    associatedtype State: Sendable
    static var initialState: State { get }

    static func processRecord(
        _ event: KeyEvent,
        state: inout State,
        context: inout FirmwareContext
    ) -> KeyEventDisposition
}
```

The feature builder preserves declaration order. The selected runtime owns the
concrete feature-state tuple and forwards QMK callbacks directly to it. Raw HID
protocol v5, RGB policy, Windows overrides, split synchronization, pointing
state, Planck hardware behavior, and Keychron common behavior all execute from
the declared Swift features.

## QMK boundary

Each `keyboards/**/keymaps/obbut` directory commits its ordinary `keymap.c`,
`config.h`, and `rules.mk`. The C keymap contains one `KC_NO` placeholder layer
because QMK requires that symbol; matrix lookup and callbacks immediately
forward to Swift. Board selection is a make definition, not a generated Swift
selector.

The shared make rules compile, in order:

1. `QMKKeymapKit` as Embedded Swift.
2. `QMKFirmwareRuntime` and protocol v5 as Embedded Swift.
3. `ObbutKeymaps` as Embedded Swift.
4. Every ordinary source in the selected firmware module, including the
   `@QMKFirmware` declaration itself.
5. The selected concrete Swift runtime and C ABI entry points.

QMK's active fork definitions, include paths, keyboard/keymap configurations,
target CPU, and ABI flags are forwarded to `swiftc`. The host macro executable
is cached in QMK's intermediate directory by Swift version and macro-source
hash. It is a compiler plugin, not a firmware generator.

VIA and dynamic keymaps are intentionally unsupported.

## Build, test, and previews

```sh
swift test --package-path SwiftKeymaps
./docker-build.sh kyria-all
./docker-build.sh elora-all
./docker-build.sh q15
./docker-build.sh planck
```

These commands invoke QMK directly. The Docker images pin Swift 6.3.3 and the
package pins SwiftSyntax 603.0.0.

Documentation is the only host-side file output:

```sh
make -C SwiftKeymaps docs ARGS='--keyboard all --output-root ..'
```

`qmk-keymap-docs` writes keymap-drawer YAML only. Firmware never consumes that
YAML. `draw-keymap.sh` runs the documentation command before rendering SVGs.

Open `SwiftKeymaps/Package.swift` in Xcode and choose My Mac for previews. Host
array traversal and erasure live in `QMKFirmwareHost`; embedded firmware targets
depend only on the allocation-free model and runtime modules.
