/// The complete renderer input for one supported keyboard model.
public struct KeymapDefinition: Equatable, Sendable {
    /// The keyboard model represented by this definition.
    public let keyboardKind: KeyboardKind

    /// The model's renderer geometry.
    public let geometry: KeyboardGeometry

    /// The ordered layers supplied by the connected firmware.
    public let supportedLayers: [KeymapLayer]

    /// The physical switches and their firmware-owned mappings.
    public let positionedKeys: [PositionedKey]

    /// The right encoder and its firmware-owned mappings.
    public let rightEncoder: KeymapEncoder

    /// Creates renderer input from a validated firmware keymap.
    ///
    /// Returns `nil` when the keymap dimensions do not match supported geometry.
    ///
    /// - Parameter firmwareKeymap: The complete firmware keymap to transform.
    public init?(firmwareKeymap: FirmwareKeymap) {
        let geometry = KeyboardGeometryCatalog.geometry(for: firmwareKeymap.keyboardKind)
        guard firmwareKeymap.layerCount >= Int(KeymapLayer.function.rawValue) + 1,
            firmwareKeymap.layerCount <= KeymapLayer.allCases.count
        else {
            return nil
        }

        let supportedLayers = Array(KeymapLayer.allCases.prefix(firmwareKeymap.layerCount))
        let matrixEntryCount =
            firmwareKeymap.layerCount
            * firmwareKeymap.matrixRowCount
            * firmwareKeymap.matrixColumnCount
        let encoderEntryCount =
            firmwareKeymap.layerCount
            * firmwareKeymap.encoderCount
            * EncoderDirection.allCases.count
        guard supportedLayers.count == firmwareKeymap.layerCount,
            firmwareKeymap.encoderCount > 0,
            firmwareKeymap.entries.count == matrixEntryCount + encoderEntryCount,
            geometry.placements.count == geometry.matrixPositions.count,
            Set(geometry.matrixPositions).count == geometry.matrixPositions.count
        else {
            return nil
        }

        let keys = geometry.matrixPositions.compactMap { position -> KeymapKey? in
            let entries = supportedLayers.compactMap { layer in
                firmwareKeymap.entry(
                    onLayer: Int(layer.rawValue),
                    row: position.row,
                    column: position.column
                )
            }
            guard entries.count == supportedLayers.count else { return nil }
            return KeymapKey(id: "r\(position.row)c\(position.column)", entries: entries)
        }
        guard keys.count == geometry.placements.count else { return nil }

        let counterclockwiseEntries = supportedLayers.compactMap { layer in
            firmwareKeymap.encoderEntry(
                onLayer: Int(layer.rawValue),
                encoderIndex: 0,
                direction: .counterclockwise
            )
        }
        let clockwiseEntries = supportedLayers.compactMap { layer in
            firmwareKeymap.encoderEntry(
                onLayer: Int(layer.rawValue),
                encoderIndex: 0,
                direction: .clockwise
            )
        }
        let pressRow = firmwareKeymap.matrixRowCount - 1
        let pressEntries = supportedLayers.compactMap { layer in
            firmwareKeymap.entry(
                onLayer: Int(layer.rawValue),
                row: pressRow,
                column: 0
            )
        }
        guard counterclockwiseEntries.count == supportedLayers.count,
            pressEntries.count == supportedLayers.count,
            clockwiseEntries.count == supportedLayers.count
        else {
            return nil
        }

        keyboardKind = firmwareKeymap.keyboardKind
        self.geometry = geometry
        self.supportedLayers = supportedLayers
        positionedKeys = zip(keys, geometry.placements).map {
            PositionedKey(key: $0, placement: $1)
        }
        rightEncoder = KeymapEncoder(
            id: "encoder-right",
            placement: geometry.rightEncoderPlacement,
            counterclockwiseKey: KeymapKey(
                id: "encoder-right-ccw",
                entries: counterclockwiseEntries
            ),
            pressKey: KeymapKey(
                id: "r\(pressRow)c0",
                entries: pressEntries
            ),
            clockwiseKey: KeymapKey(
                id: "encoder-right-cw",
                entries: clockwiseEntries
            )
        )
    }

    #if DEBUG
        /// Creates representative renderer input without a HID device.
        ///
        /// - Parameter keyboardKind: The keyboard model to represent.
        ///
        /// - Returns: Deterministic renderer input for previews and tests.
        public static func makePreview(for keyboardKind: KeyboardKind) -> KeymapDefinition {
            let layerCount =
                keyboardKind == .kyria
                ? KeymapLayer.allCases.count
                : Int(KeymapLayer.function.rawValue) + 1
            let rowCount = keyboardKind == .kyria ? 10 : 12
            let columnCount = 7
            let matrixSize = rowCount * columnCount
            let transparent = FirmwareKeymapEntry(keycode: 0x0001, semantic: .none, style: .standard)
            let unassigned = FirmwareKeymapEntry(keycode: 0x0000, semantic: .none, style: .standard)
            var entries = Array(repeating: transparent, count: layerCount * matrixSize)
            entries.replaceSubrange(0..<matrixSize, with: repeatElement(unassigned, count: matrixSize))

            let rightHomeRow = keyboardKind == .kyria ? 6 : 8
            let rightHomeKeycodes: [UInt16] = [0x0010, 0x0011, 0x0008, 0x000C, 0x0012, 0x0034]
            for (columnOffset, keycode) in rightHomeKeycodes.enumerated() {
                entries[rightHomeRow * columnCount + columnOffset + 1] = FirmwareKeymapEntry(
                    keycode: keycode,
                    semantic: .none,
                    style: .standard
                )
            }

            let pressIndex =
                Int(KeymapLayer.lower.rawValue) * matrixSize
                + (rowCount - 1) * columnCount
            entries[pressIndex] = FirmwareKeymapEntry(keycode: 0x00AE, semantic: .none, style: .standard)

            let encoderKeycodes: [(UInt16, UInt16)] = [
                (0x00AA, 0x00A9), (0x00AA, 0x00A9), (0x00AC, 0x00AB),
                (0x00AA, 0x00A9), (0x7844, 0x7843),
            ]
            for keycodes in encoderKeycodes.prefix(layerCount) {
                entries.append(FirmwareKeymapEntry(keycode: keycodes.0, semantic: .none, style: .standard))
                entries.append(FirmwareKeymapEntry(keycode: keycodes.1, semantic: .none, style: .standard))
            }
            if layerCount > encoderKeycodes.count {
                entries.append(FirmwareKeymapEntry(keycode: 0x00AA, semantic: .none, style: .standard))
                entries.append(FirmwareKeymapEntry(keycode: 0x00A9, semantic: .none, style: .standard))
            }

            let firmwareKeymap = FirmwareKeymap(
                keyboardKind: keyboardKind,
                layerCount: layerCount,
                matrixRowCount: rowCount,
                matrixColumnCount: columnCount,
                encoderCount: 1,
                fingerprint: 0,
                entries: entries
            )
            guard let definition = KeymapDefinition(firmwareKeymap: firmwareKeymap) else {
                preconditionFailure("Preview keymap must match supported geometry.")
            }
            return definition
        }
    #endif
}
