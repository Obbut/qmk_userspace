import QMKFirmwareRuntime

/// Delegates unhandled key events to Keychron's common processing hook.
public struct KeychronCommonFeature: FirmwareFeature, Sendable {
    public typealias State = EmptyFeatureState
    public static let initialState = EmptyFeatureState()

    public init() {}

    public static func postInitialize(
        state: inout EmptyFeatureState,
        context: inout FirmwareContext
    ) {
        context.unstyledLayerMask |= 1 << 1
        context.preservesBaseRGBOnLayer = UInt8.max
        context.showsOperatingSystemIndicator = false
    }

    public static func processRecord(
        _ event: KeyEvent,
        state: inout EmptyFeatureState,
        context: inout FirmwareContext
    ) -> KeyEventDisposition {
#if hasFeature(Embedded)
        return obbut_platform_process_keychron_common(
            event.keycode,
            event.isPressed ? 1 : 0
        ) != 0 ? .continueProcessing : .handled
#else
        return .continueProcessing
#endif
    }
}
