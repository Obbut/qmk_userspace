import ObbutKeymaps
import QMKFirmwareRuntime
import QMKKeymapKit

/// Shared definition for the Elora Rev2 left and right-encoder builds.
@QMKFirmware
public enum EloraFirmware {
    public typealias LayerID = ObbutLayer

    public static let id: FirmwareID = "com.obbut.elora-rev2"
    public static let layout = EloraRev2Layout()
    public static let outputName: StaticString = "elora_rev2_obbut"

    public static var keymap: some KeymapDefinition {
        SharedHalcyonLayers(layout: .elora)
        ObbutEncoder.halcyon(includesPointerLayer: false)
    }

    public static var features: some FirmwareFeatureSet {
        ObbutKeymapCompanion()
        ObbutWindowsOverrides()
        ObbutLayerLighting()
        ObbutSplitSynchronization()
    }
}

#if canImport(SwiftUI) && !hasFeature(Embedded)
import QMKKeymapRenderer
import SwiftUI

#Preview("Elora") {
    KeymapPreviewView(EloraFirmware.self)
}
#endif
