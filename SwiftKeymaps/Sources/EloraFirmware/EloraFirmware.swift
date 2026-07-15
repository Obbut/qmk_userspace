import ObbutKeymaps
import QMKFirmwareRuntime
import QMKKeymapKit

/// Swift-authored firmware composition for both Elora Rev2 halves.
public enum EloraFirmware: QMKFirmware {
    /// The shared Obbut semantic and visual domain.
    public typealias Domain = ObbutKeymapDomain

    /// The stable output base name.
    public static let outputName = "elora_rev2_obbut"

    /// The complete five-layer Elora keymap.
    public static var keymap: KeymapSpec<Domain> {
        #Keymap(
            id: "com.obbut.elora-rev2",
            layout: .splitKBEloraRev2
        ) {
            SharedHalcyonLayers(layout: .elora)
            ObbutEncoder.halcyon(includesPointerLayer: false)
        }
    }

    /// QMK settings generated for the Elora.
    public static var configuration: QMKConfiguration {
        QMKConfiguration {
            ObbutHalcyonConfiguration()
        }
    }

    /// Stateful firmware behaviors selected by the Elora.
    @FirmwareFeatureBuilder
    public static var features: FirmwareFeatures {
        ObbutKeymapCompanion()
        ObbutWindowsOverrides()
        ObbutLayerLighting()
        ObbutSplitSynchronization()
    }
}

#if canImport(SwiftUI) && !QMK_DIRECT_HOST_BUILD
import QMKKeymapRenderer
import SwiftUI

#KeymapPreview(EloraFirmware.self)
#endif
