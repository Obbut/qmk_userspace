/// Physical key positions and drawing bounds for one supported keyboard.
struct KeyboardGeometry: Equatable, Sendable {
    /// The width required by the complete split layout.
    let canvasWidth: Double

    /// The height required by the complete split layout.
    let canvasHeight: Double

    /// Key positions in the same order as the flattened keymap rows.
    let placements: [PhysicalKeyPlacement]

    /// QMK matrix coordinates in the same order as `placements`.
    let matrixPositions: [MatrixPosition]
}
