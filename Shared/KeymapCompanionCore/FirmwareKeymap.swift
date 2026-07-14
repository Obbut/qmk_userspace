/// A complete validated keymap downloaded from one keyboard.
public struct FirmwareKeymap: Equatable, Sendable {
    public let keyboardKind: KeyboardKind
    public let layerCount: Int
    public let matrixRowCount: Int
    public let matrixColumnCount: Int
    public let encoderCount: Int
    public let fingerprint: UInt32
    public let entries: [FirmwareKeymapEntry]

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

    public var hasValidFingerprint: Bool {
        calculatedFingerprint == fingerprint
    }

    public func entry(layer: Int, row: Int, column: Int) -> FirmwareKeymapEntry? {
        guard layer >= 0,
              layer < layerCount,
              row >= 0,
              row < matrixRowCount,
              column >= 0,
              column < matrixColumnCount else {
            return nil
        }
        let matrixSize = matrixRowCount * matrixColumnCount
        let index = layer * matrixSize + row * matrixColumnCount + column
        guard index < entries.count else { return nil }
        return entries[index]
    }

    public func encoderEntry(
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
