// Shared Raw HID report encoders for firmware and desktop use.
// SPDX-License-Identifier: GPL-2.0-or-later

extension KeymapProtocol {
    /// Encodes one complete keyboard-state report.
    ///
    /// - Parameters:
    ///   - bytes: Storage for exactly one report.
    ///   - keyboardKind: The keyboard identifier byte.
    ///   - highestActiveLayer: The highest active QMK layer.
    ///   - layerStateMask: The active nonpersistent layer mask.
    ///   - defaultLayerStateMask: The active persistent layer mask.
    ///   - sequence: The monotonically increasing packet sequence.
    ///   - includesRGBSettings: Whether RGB fields and capability are present.
    ///   - rgbEffect: The stable RGB effect identifier.
    ///   - rgbHue: The QMK hue component.
    ///   - rgbSaturation: The QMK saturation component.
    ///   - rgbBrightness: The QMK brightness component.
    ///   - isRGBEnabled: Whether RGB output is enabled.
    ///   - rgbSpeed: The QMK animation speed.
    /// - Returns: Whether the report was encoded successfully.
    @discardableResult
    public static func encodeStateReport(
        to bytes: UnsafeMutableBufferPointer<UInt8>,
        keyboardKind: UInt8,
        highestActiveLayer: UInt8,
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
        bytes[6] = keyboardKind
        bytes[7] = highestActiveLayer
        writeUInt32(layerStateMask, to: bytes, at: 8)
        writeUInt32(defaultLayerStateMask, to: bytes, at: 12)
        writeUInt32(sequence, to: bytes, at: 16)

        var capabilities = layerStateCapability | keymapReadCapability
        if includesRGBSettings {
            capabilities |= rgbSettingsCapability
            bytes[24] = rgbEffect
            bytes[25] = rgbHue
            bytes[26] = rgbSaturation
            bytes[27] = rgbBrightness
            bytes[28] = isRGBEnabled ? 1 : 0
            bytes[29] = rgbSpeed
            bytes[30] = rgbEffectCount
        }
        writeUInt32(capabilities, to: bytes, at: 20)
        return true
    }

    /// Encodes the metadata that begins a keymap transfer.
    ///
    /// - Parameters:
    ///   - bytes: Storage for exactly one report.
    ///   - keyboardKind: The keyboard identifier byte.
    ///   - layerCount: The number of compiled layers.
    ///   - matrixRowCount: The complete matrix row count.
    ///   - matrixColumnCount: The matrix column count.
    ///   - fingerprint: The keymap fingerprint.
    ///   - entryCount: The total number of keymap entries.
    ///   - encoderCount: The number of physical encoders represented after matrix entries.
    /// - Returns: Whether the report was encoded successfully.
    @discardableResult
    public static func encodeKeymapMetadataReport(
        to bytes: UnsafeMutableBufferPointer<UInt8>,
        keyboardKind: UInt8,
        layerCount: UInt8,
        matrixRowCount: UInt8,
        matrixColumnCount: UInt8,
        fingerprint: UInt32,
        entryCount: UInt16,
        encoderCount: UInt8
    ) -> Bool {
        guard initializeReport(bytes, as: .keymapMetadata) else { return false }
        bytes[6] = keyboardKind
        bytes[7] = layerCount
        bytes[8] = matrixRowCount
        bytes[9] = matrixColumnCount
        bytes[10] = UInt8(keymapEntrySize)
        bytes[11] = UInt8(entriesPerChunk)
        writeUInt32(fingerprint, to: bytes, at: 12)
        writeUInt16(entryCount, to: bytes, at: 16)
        bytes[18] = encoderCount
        bytes[19] = encoderDirectionCount
        return true
    }

    /// Encodes the envelope and pagination fields for a keymap chunk.
    ///
    /// - Parameters:
    ///   - bytes: Storage for exactly one report.
    ///   - keyboardKind: The keyboard identifier byte.
    ///   - entryCount: The number of entries in this chunk.
    ///   - startIndex: The first entry's layer-major offset.
    ///   - totalEntryCount: The complete keymap entry count.
    /// - Returns: Whether the pagination values fit a valid chunk.
    @discardableResult
    public static func encodeKeymapChunkHeader(
        to bytes: UnsafeMutableBufferPointer<UInt8>,
        keyboardKind: UInt8,
        entryCount: UInt8,
        startIndex: UInt16,
        totalEntryCount: UInt16
    ) -> Bool {
        guard entryCount > 0,
            Int(entryCount) <= entriesPerChunk,
            Int(startIndex) + Int(entryCount) <= Int(totalEntryCount),
            initializeReport(bytes, as: .keymapChunk)
        else {
            return false
        }
        bytes[6] = keyboardKind
        bytes[7] = entryCount
        writeUInt16(startIndex, to: bytes, at: 8)
        writeUInt16(totalEntryCount, to: bytes, at: 10)
        return true
    }

    /// Encodes one entry into an initialized keymap chunk.
    ///
    /// - Parameters:
    ///   - keycode: The compiled QMK keycode.
    ///   - semantic: The semantic override byte.
    ///   - style: The visual-style byte.
    ///   - entryIndex: The zero-based position within this chunk.
    ///   - bytes: The initialized chunk report.
    /// - Returns: Whether the entry index is present in this chunk.
    @discardableResult
    public static func encodeKeymapEntry(
        keycode: UInt16,
        semantic: UInt8,
        style: UInt8,
        at entryIndex: UInt8,
        to bytes: UnsafeMutableBufferPointer<UInt8>
    ) -> Bool {
        guard bytes.count == reportSize,
            hasValidHeader(in: UnsafeBufferPointer(bytes), messageType: .keymapChunk),
            entryIndex < bytes[7]
        else {
            return false
        }
        let offset = keymapChunkOffset + Int(entryIndex) * keymapEntrySize
        writeUInt16(keycode, to: bytes, at: offset)
        bytes[offset + 2] = semantic
        bytes[offset + 3] = style
        return true
    }

    /// Maps a zero-based QMK effect-table position to its stable wire identifier.
    ///
    /// - Parameter index: The zero-based effect-table position.
    ///
    /// - Returns: The stable identifier, or zero when the index is unsupported.
    public static func rgbEffectIdentifier(at index: UInt8) -> UInt8 {
        guard index < rgbEffectCount else { return 0 }
        return index &+ 1
    }
}
