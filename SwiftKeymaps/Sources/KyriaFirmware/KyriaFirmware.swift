import ObbutKeymaps
import QMKFirmwareRuntime
import QMKKeymapKit

/// Swift-authored firmware composition for both Kyria Rev4 halves.
public enum KyriaFirmware: QMKFirmware {
    /// The shared Obbut semantic and visual domain.
    public typealias Domain = ObbutKeymapDomain

    /// The stable output base name.
    public static let outputName = "kyria_rev4_obbut"

    /// The complete six-layer Kyria keymap.
    public static var keymap: KeymapSpec<Domain> {
        KeymapSpec(
            id: "com.obbut.kyria-rev4",
            layout: .splitKBKyriaRev4
        ) {
            SharedHalcyonLayers(layout: .kyria)
            KyriaPointerLayer()
            ObbutEncoder.halcyon(includesPointerLayer: true)
        }
    }

    /// QMK settings generated for the Kyria.
    public static var configuration: QMKConfiguration {
        QMKConfiguration {
            ObbutHalcyonConfiguration()
            AutoPointerLayer(ObbutLayer.pointer, timeout: .milliseconds(650))
        }
    }

    /// Stateful firmware behaviors selected by the Kyria.
    public static var features: FirmwareFeatures {
        ObbutKeymapCompanion()
        ObbutWindowsOverrides()
        ObbutLayerLighting()
        ObbutSplitSynchronization()
        KyriaPointerFeature()
    }
}

#if canImport(SwiftUI) && !QMK_DIRECT_HOST_BUILD
import QMKKeymapRenderer
import SwiftUI

#Preview("Kyria") {
    KeymapPreviewView(KyriaFirmware.self)
}
#endif
