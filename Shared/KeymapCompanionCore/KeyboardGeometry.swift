/// The coordinate and rotation for one physical switch.
public struct PhysicalKeyPlacement: Equatable, Sendable {
    public let centerX: Double
    public let centerY: Double
    public let rotationDegrees: Double

    public init(centerX: Double, centerY: Double, rotationDegrees: Double) {
        self.centerX = centerX
        self.centerY = centerY
        self.rotationDegrees = rotationDegrees
    }
}

/// One QMK matrix coordinate associated with a visible physical switch.
public struct MatrixPosition: Equatable, Hashable, Sendable {
    public let row: Int
    public let column: Int

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
}

/// Physical key positions and drawing bounds for one supported keyboard.
public struct KeyboardGeometry: Equatable, Sendable {
    public let canvasWidth: Double
    public let canvasHeight: Double
    public let placements: [PhysicalKeyPlacement]
    public let matrixPositions: [MatrixPosition]
    public let rightEncoderPlacement: PhysicalKeyPlacement

    public init(
        canvasWidth: Double,
        canvasHeight: Double,
        placements: [PhysicalKeyPlacement],
        matrixPositions: [MatrixPosition],
        rightEncoderPlacement: PhysicalKeyPlacement
    ) {
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
        self.placements = placements
        self.matrixPositions = matrixPositions
        self.rightEncoderPlacement = rightEncoderPlacement
    }
}

/// Physical layouts mirrored from the keymap-drawer SVGs in the repository README.
public enum KeyboardGeometryCatalog {
    public static let kyria = makeKyria()
    public static let elora = makeElora()

    public static func geometry(for keyboardKind: KeyboardKind) -> KeyboardGeometry {
        switch keyboardKind {
        case .kyria: kyria
        case .elora: elora
        }
    }

    private static func makeKyria() -> KeyboardGeometry {
        let placements = [70.0, 126.0].flatMap { matrixRow(baseline: $0) }
            + bottomRow(baseline: 182)
            + thumbClusters(verticalOffset: 0)
        let matrixPositions = matrixRowPositions(leftRow: 0, rightRow: 5)
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

    private static func makeElora() -> KeyboardGeometry {
        let placements = [70.0, 126.0, 182.0].flatMap { matrixRow(baseline: $0) }
            + bottomRow(baseline: 238)
            + thumbClusters(verticalOffset: 56)
        let matrixPositions = matrixRowPositions(leftRow: 0, rightRow: 6)
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

    private static func matrixRowPositions(leftRow: Int, rightRow: Int) -> [MatrixPosition] {
        (1...6).reversed().map { MatrixPosition(row: leftRow, column: $0) }
            + (1...6).map { MatrixPosition(row: rightRow, column: $0) }
    }

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
                MatrixPosition(row: rightInnerRow, column: 3)
            ]
            + (1...6).map { MatrixPosition(row: rightRow, column: $0) }
    }

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
            MatrixPosition(row: rightRow, column: 4)
        ]
    }

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
