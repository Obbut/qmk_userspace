/// A statically traversable set of executable firmware features.
public protocol FirmwareFeatureSet: Sendable {
    associatedtype State: Sendable

    static var initialState: State { get }

    static func postInitialize(state: inout State, context: inout FirmwareContext)
    static func housekeeping(state: inout State, context: inout FirmwareContext)
    static func processRecord(
        _ event: KeyEvent,
        state: inout State,
        context: inout FirmwareContext
    ) -> KeyEventDisposition
    static func layerStateSet(
        _ layerState: inout UInt32,
        state: inout State,
        context: inout FirmwareContext
    )
    static func pointingDeviceInitialize(state: inout State, context: inout FirmwareContext)
    static func pointingDeviceTask(
        _ report: inout PointerReport,
        state: inout State,
        context: inout FirmwareContext
    )
    static func rgbMatrixIndicators(
        _ range: RGBIndicatorRange,
        state: inout State,
        context: inout FirmwareContext
    ) -> Bool
    static func rawHIDReceive(
        _ data: UnsafeMutablePointer<UInt8>,
        length: UInt8,
        state: inout State,
        context: inout FirmwareContext
    ) -> Bool
}
