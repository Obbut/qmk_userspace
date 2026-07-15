import QMKFirmwareRuntime

/// Planck hardware LEDs and tri-layer behavior.
public struct PlanckHardwareFeature: FirmwareFeature, Sendable {
    public typealias State = EmptyFeatureState
    public static let initialState = EmptyFeatureState()

    public init() {}

    public static func postInitialize(
        state: inout EmptyFeatureState,
        context: inout FirmwareContext
    ) {
#if hasFeature(Embedded)
        obbut_platform_initialize_planck_leds()
#endif
    }

    public static func layerStateSet(
        _ layerState: inout UInt32,
        state: inout EmptyFeatureState,
        context: inout FirmwareContext
    ) {
#if hasFeature(Embedded)
        layerState = obbut_platform_update_tri_layer_state(layerState, 2, 3, 4)
#endif
    }
}
