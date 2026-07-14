/// The complete visual keymap for one supported keyboard model.
struct KeymapDefinition: Equatable, Sendable {
    /// The keyboard model represented by the definition.
    let keyboardKind: KeyboardKind

    /// Logical rows ordered from top to bottom.
    let rows: [KeymapRow]

    /// The cached physical layout used by the board renderer.
    let geometry: KeyboardGeometry

    /// Every logical key paired with its stable physical position.
    let positionedKeys: [PositionedKey]

    /// Creates a definition and validates that every logical key has one physical switch.
    /// - Parameters:
    ///   - keyboardKind: The keyboard model represented by the definition.
    ///   - rows: Logical rows in QMK layout order.
    init(keyboardKind: KeyboardKind, rows: [KeymapRow]) {
        let geometry = KeyboardGeometryCatalog.geometry(for: keyboardKind)
        let keys = rows.flatMap { $0.leftKeys + $0.rightKeys }

        precondition(
            keys.count == geometry.placements.count,
            "Keymap and physical geometry must contain the same number of keys."
        )

        self.keyboardKind = keyboardKind
        self.rows = rows
        self.geometry = geometry
        self.positionedKeys = zip(keys, geometry.placements).map {
            PositionedKey(key: $0, placement: $1)
        }
    }
}
