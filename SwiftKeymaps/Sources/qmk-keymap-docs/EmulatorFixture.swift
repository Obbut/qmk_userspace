import QMKFirmwareHost

/// A committed host-model snapshot used to validate production firmware ELFs.
struct EmulatorFixture: Encodable {
    /// The firmware output name represented by the fixture.
    private let outputName: String

    /// The number of firmware layers.
    private let layerCount: Int

    /// The physical matrix row count.
    private let matrixRows: Int

    /// The physical matrix column count.
    private let matrixColumns: Int

    /// The number of declared encoders.
    private let encoderCount: Int

    /// The protocol-v4 layout identifier.
    private let layoutID: UInt32

    /// The protocol-v4 legend metadata fingerprint.
    private let legendFingerprint: UInt32

    /// The protocol-v4 style metadata fingerprint.
    private let styleFingerprint: UInt32

    /// Layer-major, row-major, column-major keycode values.
    private let keycodes: [UInt16]

    /// Layer-major, row-major, column-major legend identifiers.
    private let legendIDs: [UInt16]

    /// Layer-major, row-major, column-major style identifiers.
    private let styleIDs: [UInt16]

    /// Layer-major, row-major, column-major packed style colors.
    private let styleColors: [UInt32]

    /// Layer-major, encoder-major, counterclockwise-then-clockwise keycodes.
    private let encoderKeycodes: [UInt16]

    /// Layer-major, encoder-major, counterclockwise-then-clockwise legend identifiers.
    private let encoderLegendIDs: [UInt16]

    /// Layer-major, encoder-major, counterclockwise-then-clockwise style identifiers.
    private let encoderStyleIDs: [UInt16]

    /// Captures every lookup value exposed by the embedded Swift C ABI.
    ///
    /// - Parameter firmware: The independently resolved host firmware model.
    init(firmware: AnyFirmware) {
        outputName = firmware.outputName
        layerCount = firmware.layers.count
        matrixRows = firmware.layout.matrixRowCount
        matrixColumns = firmware.layout.matrixColumnCount
        encoderCount = firmware.encoders.count
        layoutID = firmware.layoutID
        legendFingerprint = firmware.legendFingerprint
        styleFingerprint = firmware.styleFingerprint

        let matrixKeys = Self.matrixKeys(firmware: firmware)
        keycodes = matrixKeys.map { $0?.keycode ?? 0 }
        legendIDs = matrixKeys.map { $0?.legendID ?? 0 }
        styleIDs = matrixKeys.map { $0?.styleID ?? 0 }
        styleColors = matrixKeys.map { key in
            guard let key, key.styleID != 0,
                let style = firmware.styles.first(where: { $0.id == key.styleID })
            else {
                return 0
            }
            return (UInt32(style.color.red) << 16)
                | (UInt32(style.color.green) << 8)
                | UInt32(style.color.blue)
        }

        let encoderKeys = Self.encoderKeys(firmware: firmware)
        encoderKeycodes = encoderKeys.map { $0?.keycode ?? 0 }
        encoderLegendIDs = encoderKeys.map { $0?.legendID ?? 0 }
        encoderStyleIDs = encoderKeys.map { $0?.styleID ?? 0 }
    }

    /// Resolves every physical matrix cell for every layer.
    ///
    /// - Parameter firmware: The firmware model to traverse.
    /// - Returns: Layer-major matrix keys, using empty keys for matrix holes.
    private static func matrixKeys(firmware: AnyFirmware) -> [AnyFirmwareKey?] {
        return firmware.layers.flatMap { layer in
            var matrix = Array(
                repeating: Optional<AnyFirmwareKey>.none,
                count: firmware.layout.matrixRowCount * firmware.layout.matrixColumnCount
            )
            for (keyIndex, position) in firmware.layout.matrixMapping.enumerated() {
                let index = position.row * firmware.layout.matrixColumnCount + position.column
                matrix[index] = layer.keys[keyIndex]
            }
            return matrix
        }
    }

    /// Resolves both directions for every encoder and layer.
    ///
    /// - Parameter firmware: The firmware model to traverse.
    /// - Returns: Layer-major encoder keys in counterclockwise/clockwise order.
    private static func encoderKeys(firmware: AnyFirmware) -> [AnyFirmwareKey?] {
        return firmware.layers.flatMap { layer in
            (0..<firmware.encoders.count).flatMap { encoderIndex -> [AnyFirmwareKey?] in
                guard let encoder = firmware.encoders.first(where: { $0.index == encoderIndex }),
                    let mapping = encoder.mappings.first(where: { $0.layer == layer.id })
                else {
                    return [nil, nil]
                }
                return [Optional(mapping.counterclockwise), Optional(mapping.clockwise)]
            }
        }
    }
}
