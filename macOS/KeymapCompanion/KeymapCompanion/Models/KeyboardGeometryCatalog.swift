/// Physical layouts mirrored from the keymap-drawer SVGs in the repository README.
enum KeyboardGeometryCatalog {
    /// Exact Kyria Rev4 key centers and rotations.
    static let kyria = makeKyria()

    /// Exact Elora Rev2 key centers and rotations.
    static let elora = makeElora()

    /// Returns the cached physical geometry for a keyboard model.
    /// - Parameter keyboardKind: The keyboard whose geometry is required.
    /// - Returns: The matching physical layout.
    static func geometry(for keyboardKind: KeyboardKind) -> KeyboardGeometry {
        switch keyboardKind {
        case .kyria:
            kyria
        case .elora:
            elora
        }
    }

    /// Builds the three-row Kyria layout and its thumb fans.
    /// - Returns: The generated Kyria coordinate set.
    private static func makeKyria() -> KeyboardGeometry {
        let placements = [70.0, 126.0].flatMap { matrixRow(baseline: $0) }
            + bottomRow(baseline: 182)
            + thumbClusters(verticalOffset: 0)
        return KeyboardGeometry(
            canvasWidth: 952,
            canvasHeight: 320,
            placements: placements
        )
    }

    /// Builds the four-row Elora layout and its lower thumb fans.
    /// - Returns: The generated Elora coordinate set.
    private static func makeElora() -> KeyboardGeometry {
        let placements = [70.0, 126.0, 182.0].flatMap { matrixRow(baseline: $0) }
            + bottomRow(baseline: 238)
            + thumbClusters(verticalOffset: 56)
        return KeyboardGeometry(
            canvasWidth: 952,
            canvasHeight: 376,
            placements: placements
        )
    }

    /// Creates one mirrored 6-by-2 row with the physical column stagger.
    /// - Parameter baseline: The outside-column vertical center.
    /// - Returns: Twelve placements ordered left-outside-to-inside, then right-inside-to-outside.
    private static func matrixRow(baseline: Double) -> [PhysicalKeyPlacement] {
        let leftX = [28.0, 84.0, 140.0, 196.0, 252.0, 308.0]
        let leftYOffset = [0.0, 0.0, -28.0, -42.0, -28.0, -21.0]
        let rightX = [644.0, 700.0, 756.0, 812.0, 868.0, 924.0]
        let rightYOffset = [-21.0, -28.0, -42.0, -28.0, 0.0, 0.0]

        let left = zip(leftX, leftYOffset).map {
            PhysicalKeyPlacement(centerX: $0, centerY: baseline + $1, rotationDegrees: 0)
        }
        let right = zip(rightX, rightYOffset).map {
            PhysicalKeyPlacement(centerX: $0, centerY: baseline + $1, rotationDegrees: 0)
        }
        return left + right
    }

    /// Creates the bottom matrix row plus the four rotated inner switches.
    /// - Parameter baseline: The outside-column vertical center.
    /// - Returns: Six left switches, four inner switches, and six right switches.
    private static func bottomRow(baseline: Double) -> [PhysicalKeyPlacement] {
        let matrix = matrixRow(baseline: baseline)
        let inner = [
            PhysicalKeyPlacement(centerX: 369, centerY: baseline + 11, rotationDegrees: 30),
            PhysicalKeyPlacement(centerX: 429, centerY: baseline + 57, rotationDegrees: 45),
            PhysicalKeyPlacement(centerX: 523, centerY: baseline + 57, rotationDegrees: -45),
            PhysicalKeyPlacement(centerX: 583, centerY: baseline + 11, rotationDegrees: -30)
        ]
        return Array(matrix.prefix(6)) + inner + Array(matrix.suffix(6))
    }

    /// Creates the two five-switch thumb fans.
    /// - Parameter verticalOffset: The Elora number-row displacement, or zero for Kyria.
    /// - Returns: Ten placements ordered left-outside-to-inside, then right-inside-to-outside.
    private static func thumbClusters(verticalOffset: Double) -> [PhysicalKeyPlacement] {
        [
            PhysicalKeyPlacement(centerX: 168, centerY: 210 + verticalOffset, rotationDegrees: 0),
            PhysicalKeyPlacement(centerX: 224, centerY: 210 + verticalOffset, rotationDegrees: 0),
            PhysicalKeyPlacement(centerX: 285, centerY: 218 + verticalOffset, rotationDegrees: 15),
            PhysicalKeyPlacement(centerX: 341, centerY: 241 + verticalOffset, rotationDegrees: 30),
            PhysicalKeyPlacement(centerX: 389, centerY: 278 + verticalOffset, rotationDegrees: 45),
            PhysicalKeyPlacement(centerX: 563, centerY: 278 + verticalOffset, rotationDegrees: -45),
            PhysicalKeyPlacement(centerX: 611, centerY: 241 + verticalOffset, rotationDegrees: -30),
            PhysicalKeyPlacement(centerX: 667, centerY: 218 + verticalOffset, rotationDegrees: -15),
            PhysicalKeyPlacement(centerX: 728, centerY: 210 + verticalOffset, rotationDegrees: 0),
            PhysicalKeyPlacement(centerX: 784, centerY: 210 + verticalOffset, rotationDegrees: 0)
        ]
    }
}
