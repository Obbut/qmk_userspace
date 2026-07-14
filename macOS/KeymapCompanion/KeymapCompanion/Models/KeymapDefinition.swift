/// The complete visual keymap for one supported keyboard model.
struct KeymapDefinition: Equatable, Sendable {
    /// The keyboard model represented by the definition.
    let keyboardKind: KeyboardKind

    /// The cached physical layout used by the board renderer.
    let geometry: KeyboardGeometry

    /// Every logical key paired with its stable physical position.
    let positionedKeys: [PositionedKey]

    /// The physical right encoder and its three firmware-owned actions.
    let rightEncoder: KeymapEncoder

    /// Creates a visual definition from a complete firmware keymap.
    /// - Parameter firmwareKeymap: The validated layer-major matrix and encoder map downloaded over Raw HID.
    init?(firmwareKeymap: FirmwareKeymap) {
        let geometry = KeyboardGeometryCatalog.geometry(for: firmwareKeymap.keyboardKind)
        let matrixEntryCount = firmwareKeymap.layerCount
            * firmwareKeymap.matrixRowCount
            * firmwareKeymap.matrixColumnCount
        let encoderEntryCount = firmwareKeymap.layerCount
            * firmwareKeymap.encoderCount
            * EncoderDirection.allCases.count
        guard firmwareKeymap.layerCount == KeymapLayer.allCases.count,
              firmwareKeymap.encoderCount > 0,
              firmwareKeymap.entries.count == matrixEntryCount + encoderEntryCount,
              geometry.placements.count == geometry.matrixPositions.count,
              Set(geometry.matrixPositions).count == geometry.matrixPositions.count else {
            return nil
        }

        let keys = geometry.matrixPositions.compactMap { position -> KeymapKey? in
            let entries = KeymapLayer.allCases.compactMap { layer in
                firmwareKeymap.entry(
                    layer: Int(layer.rawValue),
                    row: position.row,
                    column: position.column
                )
            }
            guard entries.count == KeymapLayer.allCases.count else { return nil }
            return KeymapKey(id: "r\(position.row)c\(position.column)", entries: entries)
        }
        guard keys.count == geometry.placements.count else { return nil }

        let counterClockwiseEntries = KeymapLayer.allCases.compactMap { layer in
            firmwareKeymap.encoderEntry(
                layer: Int(layer.rawValue),
                encoder: 0,
                direction: .counterClockwise
            )
        }
        let clockwiseEntries = KeymapLayer.allCases.compactMap { layer in
            firmwareKeymap.encoderEntry(
                layer: Int(layer.rawValue),
                encoder: 0,
                direction: .clockwise
            )
        }
        let pressRow = firmwareKeymap.matrixRowCount - 1
        let pressEntries = KeymapLayer.allCases.compactMap { layer in
            firmwareKeymap.entry(
                layer: Int(layer.rawValue),
                row: pressRow,
                column: 0
            )
        }
        guard counterClockwiseEntries.count == KeymapLayer.allCases.count,
              pressEntries.count == KeymapLayer.allCases.count,
              clockwiseEntries.count == KeymapLayer.allCases.count else {
            return nil
        }

        keyboardKind = firmwareKeymap.keyboardKind
        self.geometry = geometry
        positionedKeys = zip(keys, geometry.placements).map {
            PositionedKey(key: $0, placement: $1)
        }
        rightEncoder = KeymapEncoder(
            id: "encoder-right",
            placement: geometry.rightEncoderPlacement,
            counterClockwiseKey: KeymapKey(
                id: "encoder-right-ccw",
                entries: counterClockwiseEntries
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
    /// Creates a representative board used by SwiftUI previews without a HID device.
    /// - Parameter keyboardKind: The physical board to preview.
    /// - Returns: A geometry-complete definition with representative right-encoder mappings.
    static func preview(for keyboardKind: KeyboardKind) -> KeymapDefinition {
        let layerCount = KeymapLayer.allCases.count
        let rowCount = keyboardKind == .kyria ? 10 : 12
        let columnCount = 7
        let matrixSize = rowCount * columnCount
        let transparent = FirmwareKeymapEntry(
            keycode: 0x0001,
            semantic: 0,
            style: .standard
        )
        let unassigned = FirmwareKeymapEntry(
            keycode: 0x0000,
            semantic: 0,
            style: .standard
        )
        var entries = Array(
            repeating: transparent,
            count: layerCount * matrixSize
        )
        entries.replaceSubrange(
            0..<matrixSize,
            with: repeatElement(unassigned, count: matrixSize)
        )

        let rightHomeRow = keyboardKind == .kyria ? 6 : 8
        let rightHomeKeycodes: [UInt16] = [
            0x0010, 0x0011, 0x0008, 0x000C, 0x0012, 0x0034
        ]
        for (columnOffset, keycode) in rightHomeKeycodes.enumerated() {
            let index = rightHomeRow * columnCount + columnOffset + 1
            entries[index] = FirmwareKeymapEntry(
                keycode: keycode,
                semantic: 0,
                style: .standard
            )
        }

        let pressIndex = Int(KeymapLayer.lower.rawValue) * matrixSize
            + (rowCount - 1) * columnCount
        entries[pressIndex] = FirmwareKeymapEntry(
            keycode: 0x00AE,
            semantic: 0,
            style: .standard
        )

        let encoderKeycodes: [
            (counterClockwise: UInt16, clockwise: UInt16)
        ] = [
            (0x00AA, 0x00A9),
            (0x00AA, 0x00A9),
            (0x00AC, 0x00AB),
            (0x00AA, 0x00A9),
            (0x7844, 0x7843)
        ]
        for keycodes in encoderKeycodes {
            entries.append(
                FirmwareKeymapEntry(
                    keycode: keycodes.counterClockwise,
                    semantic: 0,
                    style: .standard
                )
            )
            entries.append(
                FirmwareKeymapEntry(
                    keycode: keycodes.clockwise,
                    semantic: 0,
                    style: .standard
                )
            )
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
            preconditionFailure("Preview firmware keymap must match the supported geometry.")
        }
        return definition
    }
#endif
}
