/// Encoder and decoder for the versioned 32-byte QMK Raw HID protocol.
enum KeymapProtocol {
    /// QMK's default Raw HID usage page.
    static let usagePage = 0xFF60

    /// QMK's default Raw HID usage identifier.
    static let usage = 0x61

    /// QMK's Raw HID endpoint size.
    static let reportSize = 32

    /// The protocol version shared with the firmware.
    static let version: UInt8 = 1

    /// Creates a request for the keyboard's current state.
    /// - Returns: One complete Raw HID output report.
    static func makeStateRequest() -> [UInt8] {
        var report = [UInt8](repeating: 0, count: reportSize)
        report.replaceSubrange(0..<magic.count, with: magic)
        report[4] = version
        report[5] = MessageType.getState.rawValue
        return report
    }

    /// Parses a state packet while rejecting unrelated Raw HID traffic.
    /// - Parameter bytes: A complete Raw HID input report.
    /// - Returns: A validated state report, or `nil` for another protocol or version.
    static func parseStateReport(_ bytes: [UInt8]) -> KeyboardStateReport? {
        guard bytes.count == reportSize,
              Array(bytes[0..<magic.count]) == magic,
              bytes[4] == version,
              bytes[5] == MessageType.state.rawValue,
              let keyboardKind = KeyboardKind(rawValue: bytes[6]) else {
            return nil
        }

        return KeyboardStateReport(
            keyboardKind: keyboardKind,
            layerStateMask: readUInt32(from: bytes, at: 8),
            defaultLayerStateMask: readUInt32(from: bytes, at: 12),
            sequence: readUInt32(from: bytes, at: 16),
            capabilities: readUInt32(from: bytes, at: 20)
        )
    }

    /// The fixed signature that keeps the protocol separate from other QMK tools.
    private static let magic: [UInt8] = Array("KMAP".utf8)

    /// Reads a little-endian integer from a validated packet.
    /// - Parameters:
    ///   - bytes: The packet bytes.
    ///   - offset: The first byte of the integer.
    /// - Returns: The decoded integer.
    private static func readUInt32(from bytes: [UInt8], at offset: Int) -> UInt32 {
        UInt32(bytes[offset])
            | (UInt32(bytes[offset + 1]) << 8)
            | (UInt32(bytes[offset + 2]) << 16)
            | (UInt32(bytes[offset + 3]) << 24)
    }
}

/// Raw HID message types shared with the firmware.
private enum MessageType: UInt8 {
    /// Host request for an immediate state packet.
    case getState = 1

    /// Keyboard state response or unsolicited layer-change event.
    case state = 2
}
