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

    /// The number of physical encoders included after the matrix entries.
    let encoderCount: Int

    /// The firmware-provided FNV-1a fingerprint.
    let fingerprint: UInt32

    /// Matrix entries ordered by layer, row, and column, followed by layer-major encoder directions.
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

    /// Returns one rotary mapping from the encoder payload that follows the matrix.
    /// - Parameters:
    ///   - layer: The zero-based QMK layer.
    ///   - encoder: The zero-based encoder index.
    ///   - direction: The physical rotary direction.
    /// - Returns: The matching entry, or `nil` when any coordinate is invalid.
    func encoderEntry(
        layer: Int,
        encoder: Int,
        direction: EncoderDirection
    ) -> FirmwareKeymapEntry? {
        guard layer >= 0,
              layer < layerCount,
              encoder >= 0,
              encoder < encoderCount else {
            return nil
        }

        let matrixEntryCount = layerCount * matrixRowCount * matrixColumnCount
        let encoderLayerSize = encoderCount * EncoderDirection.allCases.count
        let index = matrixEntryCount
            + layer * encoderLayerSize
            + encoder * EncoderDirection.allCases.count
            + direction.rawValue
        guard index < entries.count else { return nil }
        return entries[index]
    }

    /// The checksum calculated by the shared protocol definition.
    private var calculatedFingerprint: UInt32 {
        var hash = KeymapProtocol.fingerprintSeed(
            keyboardKind: keyboardKind.rawValue,
            layerCount: UInt8(layerCount),
            matrixRowCount: UInt8(matrixRowCount),
            matrixColumnCount: UInt8(matrixColumnCount),
            encoderCount: UInt8(encoderCount)
        )
        for entry in entries {
            hash = KeymapProtocol.fingerprint(
                afterAddingKeycode: entry.keycode,
                semantic: entry.semantic,
                style: entry.style.rawValue,
                to: hash
            )
        }
        return hash
    }
}
