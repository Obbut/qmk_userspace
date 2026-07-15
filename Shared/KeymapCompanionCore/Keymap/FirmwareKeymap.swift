/// A complete validated keymap downloaded from one keyboard.
public struct FirmwareKeymap: Equatable, Sendable {
    /// The keyboard model that supplied the keymap.
    public let keyboardKind: KeyboardKind

    /// The number of firmware layers.
    public let layerCount: Int

    /// The number of rows in the complete split matrix.
    public let matrixRowCount: Int

    /// The number of columns in each matrix row.
    public let matrixColumnCount: Int

    /// The number of physical encoders.
    public let encoderCount: Int

    /// The firmware-provided FNV-1a fingerprint.
    public let fingerprint: UInt32

    /// The layer-major matrix and encoder entries.
    public let entries: [FirmwareKeymapEntry]

    /// Creates a complete firmware keymap.
    ///
    /// - Parameters:
    ///   - keyboardKind: The keyboard model that supplied the keymap.
    ///   - layerCount: The number of firmware layers.
    ///   - matrixRowCount: The number of rows in the complete split matrix.
    ///   - matrixColumnCount: The number of columns in each matrix row.
    ///   - encoderCount: The number of physical encoders.
    ///   - fingerprint: The firmware-provided FNV-1a fingerprint.
    ///   - entries: The layer-major matrix and encoder entries.
    public init(
        keyboardKind: KeyboardKind,
        layerCount: Int,
        matrixRowCount: Int,
        matrixColumnCount: Int,
        encoderCount: Int,
        fingerprint: UInt32,
        entries: [FirmwareKeymapEntry]
    ) {
        self.keyboardKind = keyboardKind
        self.layerCount = layerCount
        self.matrixRowCount = matrixRowCount
        self.matrixColumnCount = matrixColumnCount
        self.encoderCount = encoderCount
        self.fingerprint = fingerprint
        self.entries = entries
    }

    /// Whether the entries and dimensions match the firmware fingerprint.
    ///
    /// - Complexity: O(n), where n is the number of keymap entries.
    public var hasValidFingerprint: Bool {
        calculatedFingerprint == fingerprint
    }

    /// Returns the entry at one layer-major matrix coordinate.
    ///
    /// - Parameters:
    ///   - layerIndex: The zero-based layer index.
    ///   - row: The zero-based matrix row.
    ///   - column: The zero-based matrix column.
    /// - Returns: The entry, or `nil` when the coordinate is out of bounds.
    func entry(onLayer layerIndex: Int, row: Int, column: Int) -> FirmwareKeymapEntry? {
        guard layerIndex >= 0,
            layerIndex < layerCount,
            row >= 0,
            row < matrixRowCount,
            column >= 0,
            column < matrixColumnCount
        else {
            return nil
        }
        let matrixSize = matrixRowCount * matrixColumnCount
        let index = layerIndex * matrixSize + row * matrixColumnCount + column
        guard index < entries.count else { return nil }
        return entries[index]
    }

    /// Returns the entry for one encoder direction on one layer.
    ///
    /// - Parameters:
    ///   - layerIndex: The zero-based layer index.
    ///   - encoderIndex: The zero-based encoder index.
    ///   - direction: The encoder rotation direction.
    /// - Returns: The entry, or `nil` when the coordinate is out of bounds.
    func encoderEntry(
        onLayer layerIndex: Int,
        encoderIndex: Int,
        direction: EncoderDirection
    ) -> FirmwareKeymapEntry? {
        guard layerIndex >= 0,
            layerIndex < layerCount,
            encoderIndex >= 0,
            encoderIndex < encoderCount
        else {
            return nil
        }

        let matrixEntryCount = layerCount * matrixRowCount * matrixColumnCount
        let encoderLayerSize = encoderCount * EncoderDirection.allCases.count
        let index =
            matrixEntryCount
            + layerIndex * encoderLayerSize
            + encoderIndex * EncoderDirection.allCases.count
            + direction.rawValue
        guard index < entries.count else { return nil }
        return entries[index]
    }

    /// The fingerprint calculated from the keymap dimensions and entries.
    ///
    /// - Complexity: O(n), where n is the number of keymap entries.
    private var calculatedFingerprint: UInt32? {
        guard let encodedLayerCount = UInt8(exactly: layerCount),
            let encodedMatrixRowCount = UInt8(exactly: matrixRowCount),
            let encodedMatrixColumnCount = UInt8(exactly: matrixColumnCount),
            let encodedEncoderCount = UInt8(exactly: encoderCount)
        else {
            return nil
        }
        var hash = KeymapProtocol.fingerprintSeed(
            keyboardKind: keyboardKind.rawValue,
            layerCount: encodedLayerCount,
            matrixRowCount: encodedMatrixRowCount,
            matrixColumnCount: encodedMatrixColumnCount,
            encoderCount: encodedEncoderCount
        )
        for entry in entries {
            hash = KeymapProtocol.fingerprint(
                afterAddingKeycode: entry.keycode,
                semantic: entry.semantic.rawValue,
                style: entry.style.rawValue,
                to: hash
            )
        }
        return hash
    }
}
