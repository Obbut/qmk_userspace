/// A physical key placement paired with its QMK matrix coordinate.
public struct KeyPlacement: Equatable, Sendable {
    /// The matrix coordinate read from firmware.
    public let matrixPosition: MatrixPosition

    /// The renderer geometry.
    public let geometry: PhysicalKeyPlacement

    /// Creates a positioned matrix key.
    ///
    /// - Parameters:
    ///   - matrixPosition: The matrix coordinate read from firmware.
    ///   - geometry: The renderer geometry.
    public init(matrixPosition: MatrixPosition, geometry: PhysicalKeyPlacement) {
        self.matrixPosition = matrixPosition
        self.geometry = geometry
    }
}
