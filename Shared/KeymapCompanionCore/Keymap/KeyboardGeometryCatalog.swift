/// Physical layouts mirrored from the keymap-drawer SVGs in the repository README.
public enum KeyboardGeometryCatalog {
    /// The Kyria Rev4 renderer geometry.
    static let kyria = makeKyria()

    /// The Elora Rev2 renderer geometry.
    static let elora = makeElora()

    /// Returns the renderer geometry for a keyboard model.
    ///
    /// - Parameter keyboardKind: The keyboard model whose geometry is needed.
    ///
    /// - Returns: The model's renderer geometry.
    public static func geometry(for keyboardKind: KeyboardKind) -> KeyboardGeometry {
        switch keyboardKind {
        case .kyria: kyria
        case .elora: elora
        }
    }

    /// Creates the Kyria Rev4 renderer geometry.
    private static func makeKyria() -> KeyboardGeometry {
        let placements =
            [70.0, 126.0].flatMap { matrixRow(baseline: $0) }
            + bottomRow(baseline: 182)
            + thumbClusters(verticalOffset: 0)
        let matrixPositions =
            matrixRowPositions(leftRow: 0, rightRow: 5)
            + matrixRowPositions(leftRow: 1, rightRow: 6)
            + bottomRowPositions(leftRow: 2, leftInnerRow: 3, rightRow: 7, rightInnerRow: 8)
            + thumbPositions(leftRow: 3, rightRow: 8)
        return KeyboardGeometry(
            canvasWidth: 952,
            canvasHeight: 320,
            placements: placements,
            matrixPositions: matrixPositions,
            rightEncoderPlacement: PhysicalKeyPlacement(
                centerX: 583,
                centerY: 105,
                rotationDegrees: 0
            )
        )
    }

    /// Creates the Elora Rev2 renderer geometry.
    private static func makeElora() -> KeyboardGeometry {
        let placements =
            [70.0, 126.0, 182.0].flatMap { matrixRow(baseline: $0) }
            + bottomRow(baseline: 238)
            + thumbClusters(verticalOffset: 56)
        let matrixPositions =
            matrixRowPositions(leftRow: 0, rightRow: 6)
            + matrixRowPositions(leftRow: 1, rightRow: 7)
            + matrixRowPositions(leftRow: 2, rightRow: 8)
            + bottomRowPositions(leftRow: 3, leftInnerRow: 4, rightRow: 9, rightInnerRow: 10)
            + thumbPositions(leftRow: 4, rightRow: 10)
        return KeyboardGeometry(
            canvasWidth: 952,
            canvasHeight: 376,
            placements: placements,
            matrixPositions: matrixPositions,
            rightEncoderPlacement: PhysicalKeyPlacement(
                centerX: 583,
                centerY: 161,
                rotationDegrees: 0
            )
        )
    }

    /// Returns the matrix positions for one full switch row.
    ///
    /// - Parameters:
    ///   - leftRow: The matrix row for the left half.
    ///   - rightRow: The matrix row for the right half.
    /// - Returns: Positions ordered from the outside-left key to the outside-right key.
    private static func matrixRowPositions(leftRow: Int, rightRow: Int) -> [MatrixPosition] {
        (1...6).reversed().map { MatrixPosition(row: leftRow, column: $0) }
            + (1...6).map { MatrixPosition(row: rightRow, column: $0) }
    }

    /// Returns the matrix positions for the extended bottom row.
    ///
    /// - Parameters:
    ///   - leftRow: The outer row on the left half.
    ///   - leftInnerRow: The inner row on the left half.
    ///   - rightRow: The outer row on the right half.
    ///   - rightInnerRow: The inner row on the right half.
    /// - Returns: Positions ordered from the outside-left key to the outside-right key.
    private static func bottomRowPositions(
        leftRow: Int,
        leftInnerRow: Int,
        rightRow: Int,
        rightInnerRow: Int
    ) -> [MatrixPosition] {
        (1...6).reversed().map { MatrixPosition(row: leftRow, column: $0) }
            + [
                MatrixPosition(row: leftInnerRow, column: 3),
                MatrixPosition(row: leftRow, column: 0),
                MatrixPosition(row: rightRow, column: 0),
                MatrixPosition(row: rightInnerRow, column: 3),
            ]
            + (1...6).map { MatrixPosition(row: rightRow, column: $0) }
    }

    /// Returns the matrix positions for both thumb clusters.
    ///
    /// - Parameters:
    ///   - leftRow: The matrix row for the left thumb cluster.
    ///   - rightRow: The matrix row for the right thumb cluster.
    /// - Returns: Positions ordered from the outer-left thumb key to the outer-right thumb key.
    private static func thumbPositions(leftRow: Int, rightRow: Int) -> [MatrixPosition] {
        [
            MatrixPosition(row: leftRow, column: 4),
            MatrixPosition(row: leftRow, column: 2),
            MatrixPosition(row: leftRow, column: 1),
            MatrixPosition(row: leftRow, column: 5),
            MatrixPosition(row: leftRow, column: 0),
            MatrixPosition(row: rightRow, column: 0),
            MatrixPosition(row: rightRow, column: 5),
            MatrixPosition(row: rightRow, column: 1),
            MatrixPosition(row: rightRow, column: 2),
            MatrixPosition(row: rightRow, column: 4),
        ]
    }

    /// Returns the physical placements for one main matrix row.
    ///
    /// - Parameter baseline: The un-staggered vertical center of the row.
    ///
    /// - Returns: Placements ordered from the outside-left key to the outside-right key.
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

    /// Returns the physical placements for the extended bottom row.
    ///
    /// - Parameter baseline: The un-staggered vertical center of the row.
    ///
    /// - Returns: Placements ordered from the outside-left key to the outside-right key.
    private static func bottomRow(baseline: Double) -> [PhysicalKeyPlacement] {
        let matrix = matrixRow(baseline: baseline)
        let inner = [
            PhysicalKeyPlacement(centerX: 369, centerY: baseline + 11, rotationDegrees: 30),
            PhysicalKeyPlacement(centerX: 429, centerY: baseline + 57, rotationDegrees: 45),
            PhysicalKeyPlacement(centerX: 523, centerY: baseline + 57, rotationDegrees: -45),
            PhysicalKeyPlacement(centerX: 583, centerY: baseline + 11, rotationDegrees: -30),
        ]
        return Array(matrix.prefix(6)) + inner + Array(matrix.suffix(6))
    }

    /// Returns the physical placements for both thumb clusters.
    ///
    /// - Parameter verticalOffset: The model-specific downward offset.
    ///
    /// - Returns: Placements ordered from the outer-left thumb key to the outer-right thumb key.
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
            PhysicalKeyPlacement(centerX: 784, centerY: 210 + verticalOffset, rotationDegrees: 0),
        ]
    }
}
