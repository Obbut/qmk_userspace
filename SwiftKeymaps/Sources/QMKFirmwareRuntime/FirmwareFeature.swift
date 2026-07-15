/// One executable firmware behavior with its own allocation-free state.
public protocol FirmwareFeature: Sendable {
    associatedtype State: Sendable

    /// Initial state owned by the selected firmware runtime.
    static var initialState: State { get }

    /// Runs after QMK initializes the keyboard.
    static func postInitialize(state: inout State, context: inout FirmwareContext)

    /// Runs from QMK's housekeeping callback.
    static func housekeeping(state: inout State, context: inout FirmwareContext)

    /// Processes one key event in feature declaration order.
    static func processRecord(
        _ event: KeyEvent,
        state: inout State,
        context: inout FirmwareContext
    ) -> KeyEventDisposition

    /// Transforms QMK's layer state.
    static func layerStateSet(
        _ layerState: inout UInt32,
        state: inout State,
        context: inout FirmwareContext
    )

    /// Initializes pointing-device feature state.
    static func pointingDeviceInitialize(
        state: inout State,
        context: inout FirmwareContext
    )

    /// Transforms one pointing-device report.
    static func pointingDeviceTask(
        _ report: inout PointerReport,
        state: inout State,
        context: inout FirmwareContext
    )

    /// Renders advanced RGB indicators.
    static func rgbMatrixIndicators(
        _ range: RGBIndicatorRange,
        state: inout State,
        context: inout FirmwareContext
    ) -> Bool

    /// Receives one raw HID packet.
    static func rawHIDReceive(
        _ data: UnsafeMutablePointer<UInt8>,
        length: UInt8,
        state: inout State,
        context: inout FirmwareContext
    ) -> Bool
}

extension FirmwareFeature {
    public static func postInitialize(state: inout State, context: inout FirmwareContext) {}

    public static func housekeeping(state: inout State, context: inout FirmwareContext) {}

    public static func processRecord(
        _ event: KeyEvent,
        state: inout State,
        context: inout FirmwareContext
    ) -> KeyEventDisposition {
        .continueProcessing
    }

    public static func layerStateSet(
        _ layerState: inout UInt32,
        state: inout State,
        context: inout FirmwareContext
    ) {}

    public static func pointingDeviceInitialize(
        state: inout State,
        context: inout FirmwareContext
    ) {}

    public static func pointingDeviceTask(
        _ report: inout PointerReport,
        state: inout State,
        context: inout FirmwareContext
    ) {}

    public static func rgbMatrixIndicators(
        _ range: RGBIndicatorRange,
        state: inout State,
        context: inout FirmwareContext
    ) -> Bool {
        false
    }

    public static func rawHIDReceive(
        _ data: UnsafeMutablePointer<UInt8>,
        length: UInt8,
        state: inout State,
        context: inout FirmwareContext
    ) -> Bool {
        false
    }
}
