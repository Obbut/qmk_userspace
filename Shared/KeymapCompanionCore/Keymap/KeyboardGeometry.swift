/// Physical key positions and drawing bounds for one supported keyboard.
public struct KeyboardGeometry: Equatable, Sendable {
    /// The width of the renderer's logical coordinate space.
    public let canvasWidth: Double

    /// The height of the renderer's logical coordinate space.
    public let canvasHeight: Double

    /// The ordered placements of the keyboard's visible switches.
    public let placements: [PhysicalKeyPlacement]

    /// The matrix positions corresponding to ``placements``.
    public let matrixPositions: [MatrixPosition]

    /// The placement of the right encoder.
    public let rightEncoderPlacement: PhysicalKeyPlacement

    /// Creates renderer geometry for a keyboard.
    ///
    /// - Parameters:
    ///   - canvasWidth: The width of the renderer's logical coordinate space.
    ///   - canvasHeight: The height of the renderer's logical coordinate space.
    ///   - placements: The ordered placements of the keyboard's visible switches.
    ///   - matrixPositions: The matrix positions corresponding to `placements`.
    ///   - rightEncoderPlacement: The placement of the right encoder.
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
