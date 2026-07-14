// Shared Raw HID protocol for the QMK firmware and Keymap Companion.
// SPDX-License-Identifier: GPL-2.0-or-later

/// The single wire definition for communication between QMK and Keymap Companion.
enum KeymapProtocol {
    /// QMK's default Raw HID usage page.
    static let usagePage = 0xFF60

    /// QMK's default Raw HID usage identifier.
    static let usage = 0x61

    /// The byte count of every Raw HID report.
    static let reportSize = 32

    /// The current wire-format version.
    static let version: UInt8 = 3

    /// The byte count of one keycode, semantic, and style tuple.
    static let keymapEntrySize = 4

    /// The first byte occupied by entries in a keymap chunk.
    static let keymapChunkOffset = 12

    /// The maximum number of keymap entries in one report.
    static let entriesPerChunk = (reportSize - keymapChunkOffset) / keymapEntrySize

    /// The number of rotation directions encoded for every physical encoder.
    static var encoderDirectionCount: UInt8 {
        UInt8(EncoderDirection.clockwise.rawValue + 1)
    }

    /// The capability bit for realtime layer state.
    static let layerStateCapability: UInt32 = 1 << 0

    /// The capability bit for reading the compiled keymap.
    static let keymapReadCapability: UInt32 = 1 << 1

    /// The capability bit for explicit RGB Matrix settings.
    static let rgbSettingsCapability: UInt32 = 1 << 2

    /// The number of stable RGB effect identifiers.
    static var rgbEffectCount: UInt8 {
        RGBEffect.pixelFractal.rawValue
    }

    /// Message identifiers carried in byte five of a report.
    enum MessageType: UInt8 {
        /// Host request for an immediate state packet.
        case getState = 1

        /// Keyboard state response or unsolicited state-change event.
        case state = 2

        /// Host request for keymap metadata.
        case getKeymapInfo = 3

        /// Firmware keymap dimensions and fingerprint.
        case keymapInfo = 4

        /// Host request for a page of keymap entries.
        case getKeymapChunk = 5

        /// Firmware page of keymap entries.
        case keymapChunk = 6

        /// Host request to persist a complete RGB Matrix configuration.
        case setRGBSettings = 7
    }

    /// A keyboard model represented on the wire.
    enum KeyboardKind: UInt8, CaseIterable, Equatable, Sendable {
        /// The splitkb Kyria Rev4.
        case kyria = 1

        /// The splitkb Elora Rev2.
        case elora = 2
    }

    /// A semantic override for a compiled QMK keycode.
    enum KeySemantic: UInt8, Equatable, Sendable {
        /// No semantic override.
        case none = 0

        /// The macOS or Windows screenshot action.
        case screenshot = 1

        /// The Aerospace window-manager modifier chord.
        case aerospace = 2
    }

    /// A visual category assigned to a key by the firmware.
    enum KeyStyle: UInt8, Equatable, Sendable {
        /// A key without a layer-specific RGB category.
        case standard = 0

        /// A QWERTY gaming key.
        case purple = 1

        /// A navigation key.
        case magenta = 2

        /// A numeric key.
        case blue = 3

        /// A symbol key.
        case yellow = 4

        /// A function key.
        case cyan = 5

        /// An RGB increase or mode key.
        case green = 6

        /// An RGB decrease key.
        case darkGreen = 7

        /// A bootloader key.
        case red = 8

        /// A destructive editing key.
        case orange = 9
    }

    /// One rotary direction in the firmware encoder map.
    enum EncoderDirection: Int, CaseIterable, Equatable, Sendable {
        /// Counter-clockwise rotation.
        case counterClockwise = 0

        /// Clockwise rotation.
        case clockwise = 1
    }

    /// Identifies a complete report after validating its signature and version.
    /// - Parameter bytes: The bytes to validate.
    /// - Returns: The encoded message type, or `nil` for unrelated or malformed traffic.
    static func messageType(in bytes: UnsafeBufferPointer<UInt8>) -> MessageType? {
        guard bytes.count == reportSize,
              bytes[0] == 0x4B,
              bytes[1] == 0x4D,
              bytes[2] == 0x41,
              bytes[3] == 0x50,
              bytes[4] == version else {
            return nil
        }
        return MessageType(rawValue: bytes[5])
    }

    /// Checks a complete report's signature, version, and message identifier.
    /// - Parameters:
    ///   - bytes: The bytes to validate.
    ///   - type: The expected message identifier.
    /// - Returns: Whether the report matches this protocol and message type.
    static func hasValidHeader(
        _ bytes: UnsafeBufferPointer<UInt8>,
        type: MessageType
    ) -> Bool {
        messageType(in: bytes) == type
    }

    /// Clears a report and writes its common envelope.
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
        var index = 0
        while index < reportSize {
            bytes[index] = 0
            index += 1
        }
        bytes[0] = 0x4B
        bytes[1] = 0x4D
        bytes[2] = 0x41
        bytes[3] = 0x50
        bytes[4] = version
        bytes[5] = type.rawValue
        return true
    }

    /// Reads a little-endian 16-bit integer from validated report storage.
    /// - Parameters:
    ///   - bytes: The report bytes.
    ///   - offset: The first byte of the integer.
    /// - Returns: The decoded integer.
    static func readUInt16(from bytes: UnsafeBufferPointer<UInt8>, at offset: Int) -> UInt16 {
        UInt16(bytes[offset]) | (UInt16(bytes[offset + 1]) << 8)
    }

    /// Reads a little-endian 32-bit integer from validated report storage.
    /// - Parameters:
    ///   - bytes: The report bytes.
    ///   - offset: The first byte of the integer.
    /// - Returns: The decoded integer.
    static func readUInt32(from bytes: UnsafeBufferPointer<UInt8>, at offset: Int) -> UInt32 {
        UInt32(bytes[offset])
            | (UInt32(bytes[offset + 1]) << 8)
            | (UInt32(bytes[offset + 2]) << 16)
            | (UInt32(bytes[offset + 3]) << 24)
    }

    /// Writes a little-endian 16-bit integer into report storage.
    /// - Parameters:
    ///   - value: The integer to encode.
    ///   - bytes: The report bytes to modify.
    ///   - offset: The first byte to replace.
    static func writeUInt16(
        _ value: UInt16,
        to bytes: UnsafeMutableBufferPointer<UInt8>,
        at offset: Int
    ) {
        bytes[offset] = UInt8(truncatingIfNeeded: value)
        bytes[offset + 1] = UInt8(truncatingIfNeeded: value >> 8)
    }

    /// Writes a little-endian 32-bit integer into report storage.
    /// - Parameters:
    ///   - value: The integer to encode.
    ///   - bytes: The report bytes to modify.
    ///   - offset: The first byte to replace.
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

    /// Creates the FNV-1a seed after incorporating keymap dimensions.
    /// - Parameters:
    ///   - keyboardKind: The keyboard identifier byte.
    ///   - layerCount: The number of compiled layers.
    ///   - matrixRowCount: The complete matrix row count.
    ///   - matrixColumnCount: The matrix column count.
    ///   - encoderCount: The number of physical encoders.
    /// - Returns: A fingerprint ready to accept keymap entries.
    static func fingerprintSeed(
        keyboardKind: UInt8,
        layerCount: UInt8,
        matrixRowCount: UInt8,
        matrixColumnCount: UInt8,
        encoderCount: UInt8
    ) -> UInt32 {
        var hash: UInt32 = 2_166_136_261
        hash = fingerprint(afterAdding: keyboardKind, to: hash)
        hash = fingerprint(afterAdding: layerCount, to: hash)
        hash = fingerprint(afterAdding: matrixRowCount, to: hash)
        hash = fingerprint(afterAdding: matrixColumnCount, to: hash)
        hash = fingerprint(afterAdding: encoderCount, to: hash)
        return fingerprint(afterAdding: encoderDirectionCount, to: hash)
    }

    /// Adds one encoded keymap entry to an FNV-1a fingerprint.
    /// - Parameters:
    ///   - keycode: The compiled QMK keycode.
    ///   - semantic: The semantic override byte.
    ///   - style: The visual-style byte.
    ///   - fingerprint: The fingerprint accumulated so far.
    /// - Returns: The updated fingerprint.
    static func fingerprint(
        afterAddingKeycode keycode: UInt16,
        semantic: UInt8,
        style: UInt8,
        to fingerprint: UInt32
    ) -> UInt32 {
        var hash = self.fingerprint(afterAdding: UInt8(truncatingIfNeeded: keycode), to: fingerprint)
        hash = self.fingerprint(afterAdding: UInt8(truncatingIfNeeded: keycode >> 8), to: hash)
        hash = self.fingerprint(afterAdding: semantic, to: hash)
        return self.fingerprint(afterAdding: style, to: hash)
    }

    /// Adds one byte to an FNV-1a fingerprint.
    /// - Parameters:
    ///   - byte: The byte to incorporate.
    ///   - fingerprint: The fingerprint accumulated so far.
    /// - Returns: The updated fingerprint.
    private static func fingerprint(afterAdding byte: UInt8, to fingerprint: UInt32) -> UInt32 {
        (fingerprint ^ UInt32(byte)) &* 16_777_619
    }
}
