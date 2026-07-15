# Swift QMK keymaps

This package is the authored source of truth for every keymap in the repository.
It is both a normal host package for tests, rendering, and code generation and
the source tree for direct `swiftc` Embedded Swift builds inside QMK.

## The API

Semantics and presentation belong to a domain module, never the reusable QMK
framework or an individual board:

```swift
import QMKKeymapKit

public enum ObbutSemantic: UInt16, KeySemanticID {
    case screenshot = 1
    case pointerDragLock = 17
    case bluetoothHost1 = 30
}

public enum ObbutStyle: UInt16, KeyStyleID {
    case standard
    case navigation
    case wireless
}

public enum ObbutKeymapDomain: KeymapDomain {
    public typealias Semantics = SemanticCatalogValue<ObbutSemantic>
    public typealias Styles = StyleCatalogValue<ObbutStyle>

    @SemanticCatalogBuilder
    public static var semantics: Semantics {
        Semantic(.screenshot, legend: "Screenshot", symbol: .camera)
        Semantic(.pointerDragLock, legend: "Drag Lock", symbol: .lockedPointer)
        Semantic(.bluetoothHost1, legend: "Bluetooth 1", symbol: .bluetooth)
    }

    @StyleCatalogBuilder
    public static var styles: Styles {
        Style(.standard, color: .rgb(90, 90, 96))
        Style(.navigation, color: .rgb(255, 0, 255))
        Style(.wireless, color: .rgb(0, 220, 220))
    }
}
```

Shared domain actions stay typed, readable, and reusable:

```swift
private let keychronBluetoothHost1 = QMKToken("BT_HST1")

public enum ObbutKey {
    public static var screenshot: Key<ObbutKeymapDomain> {
        .four
            .withModifiers(.leftCommand, .leftControl, .leftShift)
            .semantic(.screenshot)
    }

    public static var bluetoothHost1: Key<ObbutKeymapDomain> {
        Key.qmk(
            keychronBluetoothHost1,
            legend: "Bluetooth 1",
            semantic: .bluetoothHost1,
            style: .wireless
        )
    }
}
```

An individual firmware module is only board composition and hardware policy:

```swift
import ObbutKeymaps
import QMKFirmwareRuntime

public enum KyriaFirmware: QMKFirmware {
    public typealias Domain = ObbutKeymapDomain
    public static let outputName = "kyria_rev4_obbut"

    public static var keymap: KeymapSpec<Domain> {
        KeymapSpec(id: "com.obbut.kyria-rev4", layout: .splitKBKyriaRev4) {
            SharedHalcyonLayers(layout: .kyria)
            KyriaPointerLayer()
            ObbutEncoder.halcyon(includesPointerLayer: true)
        }
    }

    public static var configuration: QMKConfiguration {
        QMKConfiguration {
            ObbutHalcyonConfiguration()
            AutoPointerLayer(ObbutLayer.pointer, timeout: .milliseconds(650))
        }
    }

    @FirmwareFeatureBuilder
    public static var features: FirmwareFeatures {
        ObbutKeymapCompanion()
        ObbutWindowsOverrides()
        ObbutLayerLighting()
        ObbutSplitSynchronization()
        KyriaPointerFeature()
    }
}

#if canImport(SwiftUI)
#Preview("Kyria") {
    KeymapPreviewView(KyriaFirmware.self)
}
#endif
```

Result builders compose heterogeneous layers, rows, encoders, configuration,
and features. Variadic generics keep feature and row composition statically
typed. The domain generic on `Key`, `KeymapSpec`, and catalogs makes mixing
unrelated semantic vocabularies a compile-time error.

## Custom firmware behavior in Swift

The direct QMK build compiles three modules in dependency order:

1. `QMKFirmwareRuntime` and protocol v4.
2. `ObbutKeymaps`, including shared state machines and behavior.
3. The selected `KyriaFirmware`, `EloraFirmware`, `Q15Firmware`, or
   `PlanckFirmware` Embedded Swift source.

Ordinary custom behavior can live directly in the shared or board module. For
a QMK callback not represented by a higher-level feature, declare host tokens
and a typed bridge in the firmware module:

```swift
private let exampleHousekeeping = QMKToken("example_housekeeping")
private let exampleProcessRecord = QMKToken("example_process_record")

@FirmwareFeatureBuilder
public static var features: FirmwareFeatures {
    ExistingSharedFeatures()
    QMKBridgeFeature(
        id: "example.custom-behavior",
        housekeeping: exampleHousekeeping,
        processRecord: exampleProcessRecord
    )
}
```

Then implement those symbols in that board's `+Embedded.swift` source:

```swift
#if hasFeature(Embedded)
@c @implementation
func example_housekeeping() {
    // Allocation-free custom Swift behavior.
}

@c @implementation
func example_process_record(_ keycode: UInt16, _ pressed: UInt8) -> UInt8 {
    // Return zero to consume the event, one to continue QMK processing.
    1
}
#endif
```

`QMKBridgeFeature` supports post-initialization, housekeeping, record
processing, layer-state transforms, pointing initialization/report transforms,
RGB Matrix indicators, and Raw HID receive. Labeled arguments select typed
callbacks, the framework validates symbol safety, and `qmk-keymapc` generates
the correctly typed declarations and composition glue. `Key.qmk` accepts either
a declared `QMKToken` or a trusted expression for fork-only and custom keycodes.

QMK configuration is authored as `QMKConfigurationComponent` values. Source,
Make, define, undefine, and include settings remain available for QMK facilities
that are inherently compile-time, so using the framework does not cap access to
QMK.

## Build and previews

Host checks:

```sh
swift test --package-path SwiftKeymaps
make -C SwiftKeymaps generate ARGS='--keyboard kyria --output-root ..'
```

Firmware builds keep the existing commands:

```sh
./docker-build.sh kyria-all
./docker-build.sh elora-all
./docker-build.sh q15
./docker-build.sh planck
```

The Docker images pin Swift 6.3.3. The host Makefile compiles `qmk-keymapc`
module-by-module directly with `swiftc`, so firmware generation has no SwiftPM
dependency. QMK Make derives the ARM target and ABI settings, compiles Embedded
Swift, and links generated, ignored C artifacts. `draw-keymap.sh` regenerates
diagram YAML from the same Swift definitions before rendering SVGs.

Open `macOS/KeymapCompanion/KeymapCompanion.xcodeproj` to edit the local package.
Each firmware constructs `KeymapPreviewView` inside Apple's discoverable
`#Preview` macro. The previews and live macOS app use `QMKKeymapRenderer` and
the same catalog-resolved document model.
