/// Adapts one concrete feature to the statically traversable feature-set protocol.
public struct FirmwareFeatureDefinition<Feature: FirmwareFeature>: FirmwareFeatureSet {
    public typealias State = Feature.State

    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ feature: Feature) {
        _ = feature
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public static var initialState: State { Feature.initialState }

    @_alwaysEmitIntoClient
    @inline(__always)
    public static func postInitialize(state: inout State, context: inout FirmwareContext) {
        Feature.postInitialize(state: &state, context: &context)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public static func housekeeping(state: inout State, context: inout FirmwareContext) {
        Feature.housekeeping(state: &state, context: &context)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public static func processRecord(
        _ event: KeyEvent,
        state: inout State,
        context: inout FirmwareContext
    ) -> KeyEventDisposition {
        Feature.processRecord(event, state: &state, context: &context)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public static func layerStateSet(
        _ layerState: inout UInt32,
        state: inout State,
        context: inout FirmwareContext
    ) {
        Feature.layerStateSet(&layerState, state: &state, context: &context)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public static func pointingDeviceInitialize(
        state: inout State,
        context: inout FirmwareContext
    ) {
        Feature.pointingDeviceInitialize(state: &state, context: &context)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public static func pointingDeviceTask(
        _ report: inout PointerReport,
        state: inout State,
        context: inout FirmwareContext
    ) {
        Feature.pointingDeviceTask(&report, state: &state, context: &context)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public static func rgbMatrixIndicators(
        _ range: RGBIndicatorRange,
        state: inout State,
        context: inout FirmwareContext
    ) -> Bool {
        Feature.rgbMatrixIndicators(range, state: &state, context: &context)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public static func rawHIDReceive(
        _ data: UnsafeMutablePointer<UInt8>,
        length: UInt8,
        state: inout State,
        context: inout FirmwareContext
    ) -> Bool {
        Feature.rawHIDReceive(data, length: length, state: &state, context: &context)
    }
}

/// Two feature sets composed in declaration order without existential erasure.
public struct FirmwareFeatureGroup<First: FirmwareFeatureSet, Second: FirmwareFeatureSet>:
    FirmwareFeatureSet
{
    public typealias State = (First.State, Second.State)

    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ first: First, _ second: Second) {
        _ = first
        _ = second
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public static var initialState: State {
        (First.initialState, Second.initialState)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public static func postInitialize(state: inout State, context: inout FirmwareContext) {
        First.postInitialize(state: &state.0, context: &context)
        Second.postInitialize(state: &state.1, context: &context)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public static func housekeeping(state: inout State, context: inout FirmwareContext) {
        First.housekeeping(state: &state.0, context: &context)
        Second.housekeeping(state: &state.1, context: &context)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public static func processRecord(
        _ event: KeyEvent,
        state: inout State,
        context: inout FirmwareContext
    ) -> KeyEventDisposition {
        let disposition = First.processRecord(event, state: &state.0, context: &context)
        guard disposition == .continueProcessing else { return disposition }
        return Second.processRecord(event, state: &state.1, context: &context)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public static func layerStateSet(
        _ layerState: inout UInt32,
        state: inout State,
        context: inout FirmwareContext
    ) {
        First.layerStateSet(&layerState, state: &state.0, context: &context)
        Second.layerStateSet(&layerState, state: &state.1, context: &context)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public static func pointingDeviceInitialize(
        state: inout State,
        context: inout FirmwareContext
    ) {
        First.pointingDeviceInitialize(state: &state.0, context: &context)
        Second.pointingDeviceInitialize(state: &state.1, context: &context)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public static func pointingDeviceTask(
        _ report: inout PointerReport,
        state: inout State,
        context: inout FirmwareContext
    ) {
        First.pointingDeviceTask(&report, state: &state.0, context: &context)
        Second.pointingDeviceTask(&report, state: &state.1, context: &context)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public static func rgbMatrixIndicators(
        _ range: RGBIndicatorRange,
        state: inout State,
        context: inout FirmwareContext
    ) -> Bool {
        let firstHandled = First.rgbMatrixIndicators(
            range,
            state: &state.0,
            context: &context
        )
        let secondHandled = Second.rgbMatrixIndicators(
            range,
            state: &state.1,
            context: &context
        )
        return firstHandled || secondHandled
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public static func rawHIDReceive(
        _ data: UnsafeMutablePointer<UInt8>,
        length: UInt8,
        state: inout State,
        context: inout FirmwareContext
    ) -> Bool {
        if First.rawHIDReceive(data, length: length, state: &state.0, context: &context) {
            return true
        }
        return Second.rawHIDReceive(data, length: length, state: &state.1, context: &context)
    }
}
