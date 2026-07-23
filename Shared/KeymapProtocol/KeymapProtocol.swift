// Shared Raw HID protocol for QMK firmware and Keymap Companion.
// SPDX-License-Identifier: GPL-2.0-or-later

#if !hasFeature(Embedded)
import QMKFirmwareRuntime
#endif

/// The protocol-v5-only wire definition shared by firmware and companion apps.
public enum KeymapProtocol {
    /// QMK's default Raw HID usage page.
    public static let usagePage = 0xFF60

    /// QMK's default Raw HID usage identifier.
    public static let usage = 0x61

    /// The byte count of every Raw HID report.
    public static let reportSize = 32

    /// The sole supported wire-format version.
    public static let version = FirmwareProtocolBridge.protocolVersion

    /// The byte count of keycode, legend ID, and style ID.
    static let keymapEntrySize = 6

    /// The first byte occupied by entries in a keymap chunk.
    static let keymapChunkOffset = 16

    /// The maximum number of entries in one report.
    static let entriesPerChunk = (reportSize - keymapChunkOffset) / keymapEntrySize

    /// The number of rotation directions encoded for each encoder.
    static let encoderDirectionCount: UInt8 = 2

    /// Deliberate confirmation required before firmware enters its bootloader.
    static let bootloaderConfirmation: UInt32 = 0x2155_4644

    /// Time allowed for the bootloader acknowledgement to leave the USB endpoint.
    static let bootloaderResetDelay: UInt32 = 50

    /// The capability bit for realtime layer state.
    public static let layerStateCapability: UInt32 = 1 << 0

    /// The capability bit for reading the compiled keymap.
    public static let keymapReadCapability: UInt32 = 1 << 1

    /// The capability bit for explicit RGB Matrix settings.
    public static let rgbSettingsCapability: UInt32 = 1 << 2

    /// Returns a report's message type after validating its signature and version.
    ///
    /// - Parameter bytes: The bytes to validate.
    /// - Returns: The encoded message type, or `nil` for malformed traffic.
    static func messageType(in bytes: UnsafeBufferPointer<UInt8>) -> MessageType? {
        guard bytes.count == reportSize,
            bytes[0] == 0x4B,
            bytes[1] == 0x4D,
            bytes[2] == 0x41,
            bytes[3] == 0x50,
            bytes[4] == version
        else { return nil }
        return MessageType(rawValue: bytes[5])
    }

    /// Returns whether a report has the expected protocol header.
    ///
    /// - Parameters:
    ///   - bytes: The bytes to validate.
    ///   - messageType: The expected message identifier.
    /// - Returns: Whether the report matches protocol v5 and the message type.
    static func hasValidHeader(
        in bytes: UnsafeBufferPointer<UInt8>,
        messageType: MessageType
    ) -> Bool {
        self.messageType(in: bytes) == messageType
    }

    /// Clears a report and writes its common envelope.
    ///
    /// - Parameters:
    ///   - bytes: Storage for exactly one report.
    ///   - type: The message identifier to encode.
    /// - Returns: Whether the supplied storage has the required size.
    @discardableResult
    static func initializeReport(
        _ bytes: UnsafeMutableBufferPointer<UInt8>,
        as type: MessageType
    ) -> Bool {
        guard bytes.count == reportSize else { return false }
        for index in 0..<reportSize { bytes[index] = 0 }
        bytes[0] = 0x4B
        bytes[1] = 0x4D
        bytes[2] = 0x41
        bytes[3] = 0x50
        bytes[4] = version
        bytes[5] = type.rawValue
        return true
    }

    /// Reads a little-endian 16-bit integer.
    static func uint16(from bytes: UnsafeBufferPointer<UInt8>, at offset: Int) -> UInt16 {
        UInt16(bytes[offset]) | (UInt16(bytes[offset + 1]) << 8)
    }

    /// Reads a little-endian 32-bit integer.
    static func uint32(from bytes: UnsafeBufferPointer<UInt8>, at offset: Int) -> UInt32 {
        UInt32(bytes[offset])
            | (UInt32(bytes[offset + 1]) << 8)
            | (UInt32(bytes[offset + 2]) << 16)
            | (UInt32(bytes[offset + 3]) << 24)
    }

    /// Writes a little-endian 16-bit integer.
    static func writeUInt16(
        _ value: UInt16,
        to bytes: UnsafeMutableBufferPointer<UInt8>,
        at offset: Int
    ) {
        bytes[offset] = UInt8(truncatingIfNeeded: value)
        bytes[offset + 1] = UInt8(truncatingIfNeeded: value >> 8)
    }

    /// Writes a little-endian 32-bit integer.
    static func writeUInt32(
        _ value: UInt32,
        to bytes: UnsafeMutableBufferPointer<UInt8>,
        at offset: Int
    ) {
        bytes[offset] = UInt8(truncatingIfNeeded: value)
        bytes[offset + 1] = UInt8(truncatingIfNeeded: value >> 8)
        bytes[offset + 2] = UInt8(truncatingIfNeeded: value >> 16)
        bytes[offset + 3] = UInt8(truncatingIfNeeded: value >> 24)
    }

    /// Returns an FNV-1a seed containing keymap identity and dimensions.
    static func fingerprintSeed(
        layoutID: UInt32,
        layerCount: UInt8,
        matrixRowCount: UInt8,
        matrixColumnCount: UInt8,
        encoderCount: UInt8
    ) -> UInt32 {
        var hash: UInt32 = 2_166_136_261
        for shift in stride(from: 0, through: 24, by: 8) {
            hash = fingerprint(afterAdding: UInt8(truncatingIfNeeded: layoutID >> UInt32(shift)), to: hash)
        }
        hash = fingerprint(afterAdding: layerCount, to: hash)
        hash = fingerprint(afterAdding: matrixRowCount, to: hash)
        hash = fingerprint(afterAdding: matrixColumnCount, to: hash)
        hash = fingerprint(afterAdding: encoderCount, to: hash)
        return fingerprint(afterAdding: encoderDirectionCount, to: hash)
    }

    /// Returns a fingerprint containing one additional keymap entry.
    static func fingerprint(
        afterAddingKeycode keycode: UInt16,
        legendID: UInt16,
        styleID: UInt16,
        to initialFingerprint: UInt32
    ) -> UInt32 {
        var hash = fingerprint(afterAdding: UInt8(truncatingIfNeeded: keycode), to: initialFingerprint)
        hash = fingerprint(afterAdding: UInt8(truncatingIfNeeded: keycode >> 8), to: hash)
        hash = fingerprint(afterAdding: UInt8(truncatingIfNeeded: legendID), to: hash)
        hash = fingerprint(afterAdding: UInt8(truncatingIfNeeded: legendID >> 8), to: hash)
        hash = fingerprint(afterAdding: UInt8(truncatingIfNeeded: styleID), to: hash)
        return fingerprint(afterAdding: UInt8(truncatingIfNeeded: styleID >> 8), to: hash)
    }

    /// Adds one byte to an FNV-1a fingerprint.
    private static func fingerprint(afterAdding byte: UInt8, to fingerprint: UInt32) -> UInt32 {
        (fingerprint ^ UInt32(byte)) &* 16_777_619
    }
}
