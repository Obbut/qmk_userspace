import ObbutKeymaps
import QMKFirmwareRuntime
import QMKKeymapKit

/// Shared definition for the Kyria Rev4 Cirque-left and encoder-right builds.
public enum KyriaFirmware: QMKFirmware {
    public typealias Domain = ObbutKeymapDomain

    public static let outputName = "kyria_rev4_obbut"

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

    public static var configuration: QMKConfiguration {
        QMKConfiguration {
            ObbutHalcyonConfiguration()
            AutoPointerLayer(ObbutLayer.pointer, timeout: .milliseconds(650))
        }
    }

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
