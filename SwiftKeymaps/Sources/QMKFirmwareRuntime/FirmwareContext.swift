/// Persistent state and narrow QMK services shared by selected features.
public struct FirmwareContext: Sendable {
    public var layerState: UInt32 = 1
    public var rgbPreviewMode = false
    public var pointerDragLockActive = false
    public var pointerFeatureActive = false
    public var unstyledLayerMask: UInt32 = 1
    public var preservesBaseRGBOnLayer: UInt8 = 1
    public var showsOperatingSystemIndicator = true
    public var legendFingerprint: UInt32 = 0
    public var styleFingerprint: UInt32 = 0

    public init() {}

    public var highestLayer: UInt8 {
        guard layerState != 0 else { return 0 }
        return UInt8(31 - layerState.leadingZeroBitCount)
    }

    public var isWindows: Bool {
#if hasFeature(Embedded)
        obbut_platform_is_windows() != 0
#else
        false
#endif
    }

    public var isKeyboardMaster: Bool {
#if hasFeature(Embedded)
        obbut_platform_is_keyboard_master() != 0
#else
        true
#endif
    }

    public var timestamp: UInt32 {
#if hasFeature(Embedded)
        obbut_platform_timer_read32()
#else
        0
#endif
    }

    public func sendKeycode(_ keycode: UInt16, isPressed: Bool) {
#if hasFeature(Embedded)
        obbut_platform_send_keycode(keycode, isPressed ? 1 : 0)
#endif
    }
}
