import QMKFirmwareRuntime

/// Protocol-v4 Keymap Companion firmware support.
public struct ObbutKeymapCompanion: FirmwareFeature, Sendable {
    public typealias State = EmptyFeatureState
    public static let initialState = EmptyFeatureState()

    public init() {}

    public static func housekeeping(
        state: inout EmptyFeatureState,
        context: inout FirmwareContext
    ) {
        guard context.isKeyboardMaster else { return }
#if OBBUT_DIAGNOSTICS && !OBBUT_BYPASS_PROTOCOL_HOUSEKEEPING
#if hasFeature(Embedded)
        obbut_crash_recovery_mark_phase(4)
#endif
        FirmwareProtocolBridge.housekeeping()
#if hasFeature(Embedded)
        obbut_crash_recovery_mark_phase(3)
#endif
#else
        FirmwareProtocolBridge.housekeeping()
#endif
    }

    public static func rawHIDReceive(
        _ data: UnsafeMutablePointer<UInt8>,
        length: UInt8,
        state: inout EmptyFeatureState,
        context: inout FirmwareContext
    ) -> Bool {
        guard length >= 5,
            data[0] == 0x4B,
            data[1] == 0x4D,
            data[2] == 0x41,
            data[3] == 0x50,
            data[4] == 4
        else {
            return false
        }
        FirmwareProtocolBridge.receive(UnsafePointer(data), length: length)
        return true
    }
}
