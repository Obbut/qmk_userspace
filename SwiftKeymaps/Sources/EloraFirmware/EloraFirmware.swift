import ObbutKeymaps
import QMKFirmwareRuntime
import QMKKeymapKit

/// Shared definition for the Elora Rev2 left and right-encoder builds.
public enum EloraFirmware: QMKFirmware {
    public typealias Domain = ObbutKeymapDomain

    public static let id = "com.obbut.elora-rev2"
    public static let layout: LayoutDescriptor = .splitKBEloraRev2
    public static let outputName = "elora_rev2_obbut"

    public static var keymap: Keymap<Domain> {
        SharedHalcyonLayers(layout: .elora)
        ObbutEncoder.halcyon(includesPointerLayer: false)
    }

    public static var configuration: QMKConfiguration {
        QMKConfiguration {
            ObbutHalcyonConfiguration()
        }
    }

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

#Preview("Elora") {
    KeymapPreviewView(EloraFirmware.self)
}
#endif
