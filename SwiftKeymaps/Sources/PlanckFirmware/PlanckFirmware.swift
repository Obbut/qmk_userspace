import ObbutKeymaps
import QMKFirmwareRuntime
import QMKKeymapKit

/// Swift-authored firmware composition for the ZSA Planck EZ Glow.
public enum PlanckFirmware: QMKFirmware {
    /// The shared Obbut semantic and visual domain.
    public typealias Domain = ObbutKeymapDomain

    /// The stable output filename without extension.
    public static let outputName = "zsa_planck_ez_glow_obbut"

    /// The complete five-layer Planck keymap.
    public static var keymap: KeymapSpec<Domain> {
        #Keymap(
            id: "com.obbut.planck-ez-glow",
            layout: .zsaPlanckEZGlow
        ) {
            SharedPlanckLayers()
        }
    }

    /// QMK settings generated for the Planck.
    public static var configuration: QMKConfiguration {
        QMKConfiguration {
            ObbutPlanckConfiguration()
        }
    }

    /// Stateful firmware behaviors selected by the Planck.
    @FirmwareFeatureBuilder
    public static var features: FirmwareFeatures {
        ObbutKeymapCompanion()
        ObbutWindowsOverrides()
        ObbutLayerLighting()
        PlanckHardwareFeature()
    }
}

#if canImport(SwiftUI) && !QMK_DIRECT_HOST_BUILD
import QMKKeymapRenderer
import SwiftUI

#KeymapPreview(PlanckFirmware.self)
#endif
