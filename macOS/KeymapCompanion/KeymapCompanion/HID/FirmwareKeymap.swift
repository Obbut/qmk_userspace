/// A complete validated keymap downloaded from one keyboard.
struct FirmwareKeymap: Equatable, Sendable {
    /// The keyboard model that supplied the keymap.
    let keyboardKind: KeyboardKind

    /// The number of compiled QMK layers.
    let layerCount: Int

    /// The number of rows in the complete split matrix.
    let matrixRowCount: Int

    /// The number of columns in each matrix row.
    let matrixColumnCount: Int

    /// The firmware-provided FNV-1a fingerprint.
    let fingerprint: UInt32

    /// Entries ordered by layer, matrix row, then matrix column.
    let entries: [FirmwareKeymapEntry]

    /// Whether the downloaded payload matches the firmware-provided fingerprint.
    var hasValidFingerprint: Bool {
        calculatedFingerprint == fingerprint
    }

    /// Returns one entry from the layer-major matrix payload.
    /// - Parameters:
    ///   - layer: The zero-based QMK layer.
    ///   - row: The zero-based matrix row.
    ///   - column: The zero-based matrix column.
    /// - Returns: The matching entry, or `nil` when any coordinate is invalid.
    func entry(layer: Int, row: Int, column: Int) -> FirmwareKeymapEntry? {
        guard layer >= 0,
              layer < layerCount,
              row >= 0,
              row < matrixRowCount,
              column >= 0,
              column < matrixColumnCount else {
            return nil
        }
        let matrixSize = matrixRowCount * matrixColumnCount
        return entries[layer * matrixSize + row * matrixColumnCount + column]
    }

    /// The FNV-1a checksum shared with protocol v2 firmware.
    private var calculatedFingerprint: UInt32 {
        var hash: UInt32 = 2_166_136_261

        func adding(_ byte: UInt8, to value: UInt32) -> UInt32 {
            (value ^ UInt32(byte)) &* 16_777_619
        }

        hash = adding(keyboardKind.rawValue, to: hash)
        hash = adding(UInt8(layerCount), to: hash)
        hash = adding(UInt8(matrixRowCount), to: hash)
        hash = adding(UInt8(matrixColumnCount), to: hash)
        for entry in entries {
            hash = adding(UInt8(truncatingIfNeeded: entry.keycode), to: hash)
            hash = adding(UInt8(truncatingIfNeeded: entry.keycode >> 8), to: hash)
            hash = adding(entry.semantic, to: hash)
            hash = adding(entry.style.rawValue, to: hash)
        }
        return hash
    }
}
