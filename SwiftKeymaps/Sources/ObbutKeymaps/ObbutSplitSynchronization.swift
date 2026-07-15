import QMKFirmwareRuntime

/// Split visual-state synchronization for Halcyon keyboards.
public struct ObbutSplitSynchronization: FirmwareFeature, Sendable {
    public struct State: Sendable {
        var lastRGBPreviewMode = false
        var lastPointerDragLockActive = false
        var lastTimestamp: UInt32 = 0

        public init() {}
    }

    public static let initialState = State()

    public init() {}

    public static func postInitialize(state: inout State, context: inout FirmwareContext) {
#if hasFeature(Embedded)
        obbut_platform_register_split_sync()
#endif
    }

    public static func housekeeping(state: inout State, context: inout FirmwareContext) {
        guard context.isKeyboardMaster else { return }
        let now = context.timestamp
        let changed = state.lastRGBPreviewMode != context.rgbPreviewMode
            || state.lastPointerDragLockActive != context.pointerDragLockActive
        guard changed || now &- state.lastTimestamp > 500 else { return }
#if hasFeature(Embedded)
        guard obbut_platform_sync_split_state(
            context.rgbPreviewMode ? 1 : 0,
            context.pointerDragLockActive ? 1 : 0
        ) != 0 else {
            return
        }
#endif
        state.lastRGBPreviewMode = context.rgbPreviewMode
        state.lastPointerDragLockActive = context.pointerDragLockActive
        state.lastTimestamp = now
    }
}
