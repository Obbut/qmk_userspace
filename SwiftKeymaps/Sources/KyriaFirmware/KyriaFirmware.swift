import ObbutKeymaps
import QMKFirmwareRuntime
import QMKKeymapKit

/// Shared definition for the Kyria Rev4 Cirque-left and encoder-right builds.
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
