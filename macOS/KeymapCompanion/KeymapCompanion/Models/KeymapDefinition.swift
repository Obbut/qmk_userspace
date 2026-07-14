/// The complete visual keymap for one supported keyboard model.
struct KeymapDefinition: Equatable, Sendable {
    /// The keyboard model represented by the definition.
    let keyboardKind: KeyboardKind

    /// The cached physical layout used by the board renderer.
    let geometry: KeyboardGeometry

    /// Every logical key paired with its stable physical position.
    let positionedKeys: [PositionedKey]

    /// Creates a visual definition from a complete firmware keymap.
    /// - Parameter firmwareKeymap: The validated layer-major matrix downloaded over Raw HID.
    init?(firmwareKeymap: FirmwareKeymap) {
        let geometry = KeyboardGeometryCatalog.geometry(for: firmwareKeymap.keyboardKind)
        guard firmwareKeymap.layerCount == KeymapLayer.allCases.count,
              firmwareKeymap.entries.count == firmwareKeymap.layerCount
                * firmwareKeymap.matrixRowCount
                * firmwareKeymap.matrixColumnCount,
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

        keyboardKind = firmwareKeymap.keyboardKind
        self.geometry = geometry
        positionedKeys = zip(keys, geometry.placements).map {
            PositionedKey(key: $0, placement: $1)
        }
    }

#if DEBUG
    /// Creates an unassigned board used by SwiftUI previews without a HID device.
    /// - Parameter keyboardKind: The physical board to preview.
    /// - Returns: A geometry-complete placeholder definition.
    static func preview(for keyboardKind: KeyboardKind) -> KeymapDefinition {
        let geometry = KeyboardGeometryCatalog.geometry(for: keyboardKind)
        let emptyEntry = FirmwareKeymapEntry(keycode: 0, semantic: 0, style: .standard)
        let keys = geometry.matrixPositions.map { position in
            KeymapKey(
                id: "r\(position.row)c\(position.column)",
                entries: Array(repeating: emptyEntry, count: KeymapLayer.allCases.count)
            )
        }
        return KeymapDefinition(
            previewKeyboardKind: keyboardKind,
            geometry: geometry,
            keys: keys
        )
    }

    /// Creates preview state after its geometry and placeholder keys are prepared.
    /// - Parameters:
    ///   - previewKeyboardKind: The physical board to preview.
    ///   - geometry: The board geometry.
    ///   - keys: Placeholder keys aligned with the geometry.
    private init(
        previewKeyboardKind: KeyboardKind,
        geometry: KeyboardGeometry,
        keys: [KeymapKey]
    ) {
        keyboardKind = previewKeyboardKind
        self.geometry = geometry
        positionedKeys = zip(keys, geometry.placements).map {
            PositionedKey(key: $0, placement: $1)
        }
    }
#endif
}
