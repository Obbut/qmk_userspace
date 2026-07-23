/// Public feature boundary to the protocol-v5 engine compiled into this module.
public enum FirmwareProtocolBridge {
    /// The sole Raw HID protocol version accepted by firmware and companion apps.
    public static let protocolVersion: UInt8 = 5

    /// Configures firmware timing from keymap-authored HUD layer metadata.
    ///
    /// - Parameter eligibleLayerMask: Layers permitted to trigger HUD presentation.
    public static func configureLayerHUD(eligibleLayerMask: UInt32) {
#if hasFeature(Embedded)
        KeymapProtocolFirmware.configureLayerHUD(eligibleLayerMask: eligibleLayerMask)
#endif
    }

    /// Records one key-down as activity for an armed layer-HUD timer.
    ///
    /// - Parameter timestamp: The current wraparound QMK millisecond timestamp.
    public static func recordKeyDown(at timestamp: UInt32) {
#if hasFeature(Embedded)
        KeymapProtocolFirmware.recordKeyDown(at: timestamp)
#endif
    }

    public static func receive(_ data: UnsafePointer<UInt8>, length: UInt8) {
#if hasFeature(Embedded)
        KeymapProtocolFirmware.receive(data, length: length)
#endif
    }

    public static func housekeeping() {
#if hasFeature(Embedded)
        KeymapProtocolFirmware.performHousekeeping()
#endif
    }
}
