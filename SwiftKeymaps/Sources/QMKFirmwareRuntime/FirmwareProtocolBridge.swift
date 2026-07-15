/// Public feature boundary to the protocol-v4 engine compiled into this module.
public enum FirmwareProtocolBridge {
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
