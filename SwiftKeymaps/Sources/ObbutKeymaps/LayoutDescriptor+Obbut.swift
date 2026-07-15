import QMKKeymapKit

/// Obbut keyboard layouts expressed entirely in Swift.
public extension LayoutDescriptor {
    /// The SplitKB Kyria Rev4 Halcyon layout.
    static let splitKBKyriaRev4 = ObbutLayoutFactory.kyria()

    /// The SplitKB Elora Rev2 Halcyon layout.
    static let splitKBEloraRev2 = ObbutLayoutFactory.elora()

    /// The Keychron Q15 Max ANSI layout with two encoders.
    static let keychronQ15Max = ObbutLayoutFactory.q15()

    /// The ZSA Planck EZ Glow layout with a two-unit center spacebar.
    static let zsaPlanckEZGlow = ObbutLayoutFactory.planck()
}

/// Produces physical geometry and matrix mappings for the Obbut layouts.
fileprivate enum ObbutLayoutFactory {
    /// Creates the Kyria layout descriptor.
    static func kyria() -> LayoutDescriptor {
        let placements =
            [70.0, 126.0].flatMap { splitMatrixRow(baseline: $0) }
            + splitBottomRow(baseline: 182)
            + splitThumbClusters(verticalOffset: 0)
        let positions =
            splitMatrixPositions(leftRow: 0, rightRow: 5)
            + splitMatrixPositions(leftRow: 1, rightRow: 6)
            + splitBottomPositions(leftRow: 2, leftInnerRow: 3, rightRow: 7, rightInnerRow: 8)
            + splitThumbPositions(leftRow: 3, rightRow: 8)
        return LayoutDescriptor(
            id: "splitkb.halcyon.kyria.rev4",
            displayName: "Kyria Rev4",
            cMacro: "LAYOUT_split_3x6_5_hlc",
            keyCount: 60,
            matrixRowCount: 10,
            matrixColumnCount: 7,
            matrixMapping: positions + modulePositions(leftRow: 4, rightRow: 9),
            canvasWidth: 952,
            canvasHeight: 320,
            keys: zip(positions, placements).map {
                KeyPlacement(matrixPosition: $0, geometry: $1)
            },
            encoders: [
                EncoderPlacement(
                    id: "right",
                    index: 0,
                    geometry: PhysicalKeyPlacement(centerX: 583, centerY: 105),
                    pressPosition: MatrixPosition(row: 9, column: 0)
                )
            ]
        )
    }

    /// Creates the Elora layout descriptor.
    static func elora() -> LayoutDescriptor {
        let placements =
            [70.0, 126.0, 182.0].flatMap { splitMatrixRow(baseline: $0) }
            + splitBottomRow(baseline: 238)
            + splitThumbClusters(verticalOffset: 56)
        let positions =
            splitMatrixPositions(leftRow: 0, rightRow: 6)
            + splitMatrixPositions(leftRow: 1, rightRow: 7)
            + splitMatrixPositions(leftRow: 2, rightRow: 8)
            + splitBottomPositions(leftRow: 3, leftInnerRow: 4, rightRow: 9, rightInnerRow: 10)
            + splitThumbPositions(leftRow: 4, rightRow: 10)
        return LayoutDescriptor(
            id: "splitkb.halcyon.elora.rev2",
            displayName: "Elora Rev2",
            cMacro: "LAYOUT_elora_hlc",
            keyCount: 72,
            matrixRowCount: 12,
            matrixColumnCount: 7,
            matrixMapping: positions + modulePositions(leftRow: 5, rightRow: 11),
            canvasWidth: 952,
            canvasHeight: 376,
            keys: zip(positions, placements).map {
                KeyPlacement(matrixPosition: $0, geometry: $1)
            },
            encoders: [
                EncoderPlacement(
                    id: "right",
                    index: 0,
                    geometry: PhysicalKeyPlacement(centerX: 583, centerY: 161),
                    pressPosition: MatrixPosition(row: 11, column: 0)
                )
            ]
        )
    }

    /// Creates the Q15 layout descriptor.
    static func q15() -> LayoutDescriptor {
        let rows: [[(Int, Double, Double, Double)]] = [
            (0..<14).map { ($0, Double($0), 0, 1) },
            (0..<14).map { ($0, Double($0), 1, 1) },
            (0..<12).map { ($0, Double($0), 2, 1) } + [(13, 12, 2, 2)],
            (0..<14).map { ($0, Double($0), 3, 1) },
            [
                (0, 0, 4, 1), (1, 1, 4, 1), (2, 2, 4, 1), (3, 3, 4, 1),
                (4, 4, 4, 2.25), (6, 6.25, 4, 2.75), (7, 9, 4, 1),
                (8, 10, 4, 1), (10, 11, 4, 1), (11, 12, 4, 1), (13, 13, 4, 1),
            ],
        ]
        let keys = rows.enumerated().flatMap { row, entries in
            entries.map { column, x, y, width in
                KeyPlacement(
                    matrixPosition: MatrixPosition(row: row, column: column),
                    geometry: PhysicalKeyPlacement(
                        centerX: (x + width / 2) * 56,
                        centerY: (y + 0.5) * 56,
                        width: width
                    )
                )
            }
        }
        return LayoutDescriptor(
            id: "keychron.q15-max.ansi-encoder",
            displayName: "Keychron Q15 Max",
            cMacro: "LAYOUT_ansi_66",
            keyCount: 66,
            matrixRowCount: 5,
            matrixColumnCount: 14,
            matrixMapping: keys.map(\.matrixPosition),
            canvasWidth: 784,
            canvasHeight: 280,
            keys: keys,
            encoders: [
                EncoderPlacement(
                    id: "left",
                    index: 0,
                    geometry: PhysicalKeyPlacement(centerX: 28, centerY: 28),
                    pressPosition: MatrixPosition(row: 0, column: 0)
                ),
                EncoderPlacement(
                    id: "right",
                    index: 1,
                    geometry: PhysicalKeyPlacement(centerX: 756, centerY: 28),
                    pressPosition: MatrixPosition(row: 0, column: 13)
                ),
            ]
        )
    }

    /// Creates the Planck layout descriptor.
    static func planck() -> LayoutDescriptor {
        let positions =
            splitPlanckRow(leftRow: 0, rightRow: 4)
            + splitPlanckRow(leftRow: 1, rightRow: 5)
            + splitPlanckRow(leftRow: 2, rightRow: 6)
            + [
                MatrixPosition(row: 3, column: 0),
                MatrixPosition(row: 3, column: 1),
                MatrixPosition(row: 3, column: 2),
                MatrixPosition(row: 7, column: 3),
                MatrixPosition(row: 7, column: 4),
                MatrixPosition(row: 7, column: 5),
                MatrixPosition(row: 7, column: 0),
                MatrixPosition(row: 7, column: 1),
                MatrixPosition(row: 7, column: 2),
                MatrixPosition(row: 3, column: 3),
                MatrixPosition(row: 3, column: 4),
            ]
        let placements =
            (0..<36).map { index in
                PhysicalKeyPlacement(
                    centerX: (Double(index % 12) + 0.5) * 56,
                    centerY: (Double(index / 12) + 0.5) * 56
                )
            }
            + (0..<11).map { index in
                let x: Double
                let width: Double
                if index == 5 {
                    x = 6
                    width = 2
                } else if index > 5 {
                    x = Double(index + 1)
                    width = 1
                } else {
                    x = Double(index)
                    width = 1
                }
                return PhysicalKeyPlacement(
                    centerX: (x + width / 2) * 56,
                    centerY: 196,
                    width: width
                )
            }
        return LayoutDescriptor(
            id: "zsa.planck-ez.glow",
            displayName: "Planck EZ Glow",
            cMacro: "LAYOUT_planck_1x2uC",
            keyCount: 47,
            matrixRowCount: 8,
            matrixColumnCount: 6,
            matrixMapping: positions,
            canvasWidth: 672,
            canvasHeight: 224,
            keys: zip(positions, placements).map {
                KeyPlacement(matrixPosition: $0, geometry: $1)
            },
            encoders: []
        )
    }

    /// Returns matrix positions for one complete split row.
    static func splitMatrixPositions(leftRow: Int, rightRow: Int) -> [MatrixPosition] {
        (1...6).reversed().map { MatrixPosition(row: leftRow, column: $0) }
            + (1...6).map { MatrixPosition(row: rightRow, column: $0) }
    }

    /// Returns matrix positions for a split keyboard's extended bottom row.
    static func splitBottomPositions(
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

    /// Returns matrix positions for both split thumb clusters.
    static func splitThumbPositions(leftRow: Int, rightRow: Int) -> [MatrixPosition] {
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

    /// Returns the ten Halcyon module arguments appended after physical switches.
    static func modulePositions(leftRow: Int, rightRow: Int) -> [MatrixPosition] {
        (0..<5).map { MatrixPosition(row: leftRow, column: $0) }
            + (0..<5).map { MatrixPosition(row: rightRow, column: $0) }
    }

    /// Returns physical placements for one staggered split row.
    static func splitMatrixRow(baseline: Double) -> [PhysicalKeyPlacement] {
        let leftX = [28.0, 84.0, 140.0, 196.0, 252.0, 308.0]
        let leftYOffset = [0.0, 0.0, -28.0, -42.0, -28.0, -21.0]
        let rightX = [644.0, 700.0, 756.0, 812.0, 868.0, 924.0]
        let rightYOffset = [-21.0, -28.0, -42.0, -28.0, 0.0, 0.0]
        let left = zip(leftX, leftYOffset).map {
            PhysicalKeyPlacement(centerX: $0, centerY: baseline + $1)
        }
        let right = zip(rightX, rightYOffset).map {
            PhysicalKeyPlacement(centerX: $0, centerY: baseline + $1)
        }
        return left + right
    }

    /// Returns physical placements for a split keyboard's extended bottom row.
    static func splitBottomRow(baseline: Double) -> [PhysicalKeyPlacement] {
        let matrix = splitMatrixRow(baseline: baseline)
        let inner = [
            PhysicalKeyPlacement(centerX: 369, centerY: baseline + 11, rotationDegrees: 30),
            PhysicalKeyPlacement(centerX: 429, centerY: baseline + 57, rotationDegrees: 45),
            PhysicalKeyPlacement(centerX: 523, centerY: baseline + 57, rotationDegrees: -45),
            PhysicalKeyPlacement(centerX: 583, centerY: baseline + 11, rotationDegrees: -30),
        ]
        return Array(matrix.prefix(6)) + inner + Array(matrix.suffix(6))
    }

    /// Returns physical placements for both split thumb clusters.
    static func splitThumbClusters(verticalOffset: Double) -> [PhysicalKeyPlacement] {
        [
            PhysicalKeyPlacement(centerX: 168, centerY: 210 + verticalOffset),
            PhysicalKeyPlacement(centerX: 224, centerY: 210 + verticalOffset),
            PhysicalKeyPlacement(centerX: 285, centerY: 218 + verticalOffset, rotationDegrees: 15),
            PhysicalKeyPlacement(centerX: 341, centerY: 241 + verticalOffset, rotationDegrees: 30),
            PhysicalKeyPlacement(centerX: 389, centerY: 278 + verticalOffset, rotationDegrees: 45),
            PhysicalKeyPlacement(centerX: 563, centerY: 278 + verticalOffset, rotationDegrees: -45),
            PhysicalKeyPlacement(centerX: 611, centerY: 241 + verticalOffset, rotationDegrees: -30),
            PhysicalKeyPlacement(centerX: 667, centerY: 218 + verticalOffset, rotationDegrees: -15),
            PhysicalKeyPlacement(centerX: 728, centerY: 210 + verticalOffset),
            PhysicalKeyPlacement(centerX: 784, centerY: 210 + verticalOffset),
        ]
    }

    /// Returns Planck matrix positions for one visible twelve-key row.
    static func splitPlanckRow(leftRow: Int, rightRow: Int) -> [MatrixPosition] {
        (0..<6).map { MatrixPosition(row: leftRow, column: $0) }
            + (0..<6).map { MatrixPosition(row: rightRow, column: $0) }
    }
}
