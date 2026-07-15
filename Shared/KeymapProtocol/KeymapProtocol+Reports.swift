// Protocol-v4 Raw HID report encoders.
// SPDX-License-Identifier: GPL-2.0-or-later

/// Firmware-side protocol-v4 report encoders.
extension KeymapProtocol {
    /// Encodes acknowledgement of an accepted bootloader request.
    @discardableResult
    public static func encodeBootloaderAcknowledgement(
        to bytes: UnsafeMutableBufferPointer<UInt8>
    ) -> Bool {
        guard initializeReport(bytes, as: .bootloaderAcknowledgement) else { return false }
        writeUInt32(bootloaderConfirmation, to: bytes, at: 6)
        return true
    }

    /// Encodes one complete keyboard-state report.
    @discardableResult
    public static func encodeStateReport(
        to bytes: UnsafeMutableBufferPointer<UInt8>,
        layoutID: UInt32,
        layerStateMask: UInt32,
        defaultLayerStateMask: UInt32,
        sequence: UInt32,
        includesRGBSettings: Bool,
        rgbEffect: UInt8,
        rgbHue: UInt8,
        rgbSaturation: UInt8,
        rgbBrightness: UInt8,
        isRGBEnabled: Bool,
        rgbSpeed: UInt8
    ) -> Bool {
        guard initializeReport(bytes, as: .state) else { return false }
        writeUInt32(layoutID, to: bytes, at: 6)
        writeUInt32(layerStateMask, to: bytes, at: 10)
        writeUInt32(defaultLayerStateMask, to: bytes, at: 14)
        writeUInt32(sequence, to: bytes, at: 18)
        var capabilities = layerStateCapability | keymapReadCapability
        if includesRGBSettings {
            capabilities |= rgbSettingsCapability
            bytes[26] = rgbEffect
            bytes[27] = rgbHue
            bytes[28] = rgbSaturation
            bytes[29] = rgbBrightness
            bytes[30] = isRGBEnabled ? 1 : 0
            bytes[31] = rgbSpeed
        }
        writeUInt32(capabilities, to: bytes, at: 22)
        return true
    }

    /// Encodes keymap dimensions and generated metadata fingerprints.
    @discardableResult
    public static func encodeKeymapMetadataReport(
        to bytes: UnsafeMutableBufferPointer<UInt8>,
        layoutID: UInt32,
        layerCount: UInt8,
        matrixRowCount: UInt8,
        matrixColumnCount: UInt8,
        fingerprint: UInt32,
        semanticFingerprint: UInt32,
        styleFingerprint: UInt32,
        entryCount: UInt16,
        encoderCount: UInt8
    ) -> Bool {
        guard initializeReport(bytes, as: .keymapMetadata) else { return false }
        writeUInt32(layoutID, to: bytes, at: 6)
        bytes[10] = layerCount
        bytes[11] = matrixRowCount
        bytes[12] = matrixColumnCount
        bytes[13] = UInt8(keymapEntrySize)
        bytes[14] = UInt8(entriesPerChunk)
        bytes[15] = encoderCount
        writeUInt16(entryCount, to: bytes, at: 16)
        writeUInt32(fingerprint, to: bytes, at: 18)
        writeUInt32(semanticFingerprint, to: bytes, at: 22)
        writeUInt32(styleFingerprint, to: bytes, at: 26)
        bytes[30] = encoderDirectionCount
        return true
    }

    /// Encodes the envelope for one page of keymap entries.
    @discardableResult
    public static func encodeKeymapChunkHeader(
        to bytes: UnsafeMutableBufferPointer<UInt8>,
        layoutID: UInt32,
        entryCount: UInt8,
        startIndex: UInt16,
        totalEntryCount: UInt16
    ) -> Bool {
        guard entryCount > 0,
            Int(entryCount) <= entriesPerChunk,
            Int(startIndex) + Int(entryCount) <= Int(totalEntryCount),
            initializeReport(bytes, as: .keymapChunk)
        else { return false }
        writeUInt32(layoutID, to: bytes, at: 6)
        writeUInt16(startIndex, to: bytes, at: 10)
        writeUInt16(totalEntryCount, to: bytes, at: 12)
        bytes[14] = entryCount
        return true
    }

    /// Encodes one keycode and its generated metadata identifiers.
    @discardableResult
    public static func encodeKeymapEntry(
        keycode: UInt16,
        semanticID: UInt16,
        styleID: UInt16,
        at entryIndex: UInt8,
        to bytes: UnsafeMutableBufferPointer<UInt8>
    ) -> Bool {
        guard bytes.count == reportSize,
            hasValidHeader(in: UnsafeBufferPointer(bytes), messageType: .keymapChunk),
            entryIndex < bytes[14]
        else { return false }
        let offset = keymapChunkOffset + Int(entryIndex) * keymapEntrySize
        writeUInt16(keycode, to: bytes, at: offset)
        writeUInt16(semanticID, to: bytes, at: offset + 2)
        writeUInt16(styleID, to: bytes, at: offset + 4)
        return true
    }
}
