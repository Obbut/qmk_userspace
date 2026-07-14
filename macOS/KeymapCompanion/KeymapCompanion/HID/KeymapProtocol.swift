/// Encoder and decoder for the versioned 32-byte QMK Raw HID protocol.
enum KeymapProtocol {
    /// QMK's default Raw HID usage page.
    static let usagePage = 0xFF60

    /// QMK's default Raw HID usage identifier.
    static let usage = 0x61

    /// QMK's Raw HID endpoint size.
    static let reportSize = 32

    /// The protocol version shared with the firmware.
    static let version: UInt8 = 2

    /// The byte count of one keycode, semantic, and style tuple.
    static let keymapEntrySize = 4

    /// The firmware capability bit for explicit RGB Matrix settings.
    static let rgbSettingsCapability: UInt32 = 1 << 2

    /// Creates a request for the keyboard's current state.
    /// - Returns: One complete Raw HID output report.
    static func makeStateRequest() -> [UInt8] {
        makeRequest(type: .getState)
    }

    /// Creates a request for the firmware's keymap dimensions and fingerprint.
    /// - Returns: One complete Raw HID output report.
    static func makeKeymapMetadataRequest() -> [UInt8] {
        makeRequest(type: .getKeymapInfo)
    }

    /// Creates a request for consecutive keymap entries.
    /// - Parameter startIndex: The first layer-major matrix entry to return.
    /// - Returns: One complete Raw HID output report.
    static func makeKeymapChunkRequest(startingAt startIndex: UInt16) -> [UInt8] {
        var report = makeRequest(type: .getKeymapChunk)
        writeUInt16(startIndex, to: &report, at: 6)
        return report
    }

    /// Creates a request that persists an explicit RGB Matrix configuration.
    /// - Parameter settings: The complete base-layer configuration to apply.
    /// - Returns: One complete Raw HID output report.
    static func makeRGBSettingsRequest(_ settings: RGBSettings) -> [UInt8] {
        var report = makeRequest(type: .setRGBSettings)
        report[6] = settings.isEnabled ? 1 : 0
        report[7] = settings.effect.rawValue
        report[8] = settings.hue
        report[9] = settings.saturation
        report[10] = min(settings.brightness, RGBSettings.maximumBrightness)
        report[11] = settings.speed
        return report
    }

    /// Parses a state packet while rejecting unrelated Raw HID traffic.
    /// - Parameter bytes: A complete Raw HID input report.
    /// - Returns: A validated state report, or `nil` for another protocol or version.
    static func parseStateReport(_ bytes: [UInt8]) -> KeyboardStateReport? {
        guard hasValidHeader(bytes, type: .state),
              let keyboardKind = KeyboardKind(rawValue: bytes[6]) else {
            return nil
        }

        let capabilities = readUInt32(from: bytes, at: 20)
        let rgbSettings: RGBSettings?
        if capabilities & rgbSettingsCapability != 0,
           let effect = RGBEffect(rawValue: bytes[24]) {
            rgbSettings = RGBSettings(
                isEnabled: bytes[28] != 0,
                effect: effect,
                hue: bytes[25],
                saturation: bytes[26],
                brightness: min(bytes[27], RGBSettings.maximumBrightness),
                speed: bytes[29]
            )
        } else {
            rgbSettings = nil
        }

        return KeyboardStateReport(
            keyboardKind: keyboardKind,
            layerStateMask: readUInt32(from: bytes, at: 8),
            defaultLayerStateMask: readUInt32(from: bytes, at: 12),
            sequence: readUInt32(from: bytes, at: 16),
            capabilities: capabilities,
            rgbSettings: rgbSettings
        )
    }

    /// Parses the packet that begins a complete keymap transfer.
    /// - Parameter bytes: A complete Raw HID input report.
    /// - Returns: Validated transfer metadata, or `nil` for another packet type.
    static func parseKeymapMetadataReport(_ bytes: [UInt8]) -> KeymapMetadataReport? {
        guard hasValidHeader(bytes, type: .keymapInfo),
              let keyboardKind = KeyboardKind(rawValue: bytes[6]) else {
            return nil
        }

        let layerCount = Int(bytes[7])
        let matrixRowCount = Int(bytes[8])
        let matrixColumnCount = Int(bytes[9])
        let entrySize = Int(bytes[10])
        let entriesPerChunk = Int(bytes[11])
        let entryCount = Int(readUInt16(from: bytes, at: 16))
        guard layerCount > 0,
              layerCount <= 32,
              matrixRowCount > 0,
              matrixColumnCount > 0,
              entrySize == keymapEntrySize,
              entriesPerChunk > 0,
              entriesPerChunk * entrySize <= reportSize - 12,
              entryCount == layerCount * matrixRowCount * matrixColumnCount else {
            return nil
        }

        return KeymapMetadataReport(
            keyboardKind: keyboardKind,
            layerCount: layerCount,
            matrixRowCount: matrixRowCount,
            matrixColumnCount: matrixColumnCount,
            entrySize: entrySize,
            entriesPerChunk: entriesPerChunk,
            fingerprint: readUInt32(from: bytes, at: 12),
            entryCount: entryCount
        )
    }

    /// Parses one page of layer-major matrix entries.
    /// - Parameter bytes: A complete Raw HID input report.
    /// - Returns: A validated page, or `nil` for another or malformed packet.
    static func parseKeymapChunkReport(_ bytes: [UInt8]) -> KeymapChunkReport? {
        guard hasValidHeader(bytes, type: .keymapChunk),
              let keyboardKind = KeyboardKind(rawValue: bytes[6]) else {
            return nil
        }

        let count = Int(bytes[7])
        let startIndex = Int(readUInt16(from: bytes, at: 8))
        let totalEntryCount = Int(readUInt16(from: bytes, at: 10))
        guard count > 0,
              12 + count * keymapEntrySize <= reportSize,
              startIndex + count <= totalEntryCount else {
            return nil
        }

        var entries: [FirmwareKeymapEntry] = []
        entries.reserveCapacity(count)
        for entryIndex in 0..<count {
            let offset = 12 + entryIndex * keymapEntrySize
            guard let style = KeyStyle(rawValue: bytes[offset + 3]) else { return nil }
            entries.append(
                FirmwareKeymapEntry(
                    keycode: readUInt16(from: bytes, at: offset),
                    semantic: bytes[offset + 2],
                    style: style
                )
            )
        }
        return KeymapChunkReport(
            keyboardKind: keyboardKind,
            startIndex: startIndex,
            totalEntryCount: totalEntryCount,
            entries: entries
        )
    }

    /// Creates a zero-filled request with the shared envelope.
    /// - Parameter type: The host-to-firmware message type.
    /// - Returns: One complete output report.
    private static func makeRequest(type: MessageType) -> [UInt8] {
        var report = [UInt8](repeating: 0, count: reportSize)
        report.replaceSubrange(0..<magic.count, with: magic)
        report[4] = version
        report[5] = type.rawValue
        return report
    }

    /// Checks the common protocol signature and expected packet type.
    /// - Parameters:
    ///   - bytes: The received report.
    ///   - type: The expected firmware-to-host message type.
    /// - Returns: Whether the packet has the correct size, signature, version, and type.
    private static func hasValidHeader(_ bytes: [UInt8], type: MessageType) -> Bool {
        bytes.count == reportSize
            && Array(bytes[0..<magic.count]) == magic
            && bytes[4] == version
            && bytes[5] == type.rawValue
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

    /// Reads a little-endian 16-bit integer from a validated packet.
    /// - Parameters:
    ///   - bytes: The packet bytes.
    ///   - offset: The first byte of the integer.
    /// - Returns: The decoded integer.
    private static func readUInt16(from bytes: [UInt8], at offset: Int) -> UInt16 {
        UInt16(bytes[offset]) | (UInt16(bytes[offset + 1]) << 8)
    }

    /// Writes a little-endian 16-bit integer into an output packet.
    /// - Parameters:
    ///   - value: The integer to encode.
    ///   - bytes: The output packet.
    ///   - offset: The first byte to replace.
    private static func writeUInt16(_ value: UInt16, to bytes: inout [UInt8], at offset: Int) {
        bytes[offset] = UInt8(truncatingIfNeeded: value)
        bytes[offset + 1] = UInt8(truncatingIfNeeded: value >> 8)
    }
}

/// Raw HID message types shared with the firmware.
private enum MessageType: UInt8 {
    /// Host request for an immediate state packet.
    case getState = 1

    /// Keyboard state response or unsolicited layer-change event.
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
