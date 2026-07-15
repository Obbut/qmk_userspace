/// The physical geometry of one key or encoder.
public struct PhysicalKeyPlacement: Equatable, Sendable {
    /// The horizontal center in renderer units.
    public let centerX: Double

    /// The vertical center in renderer units.
    public let centerY: Double

    /// The key width in standard key units.
    public let width: Double

    /// The key height in standard key units.
    public let height: Double

    /// The clockwise rotation in degrees.
    public let rotationDegrees: Double

    /// Creates physical control geometry.
    ///
    /// - Parameters:
    ///   - centerX: The horizontal center in renderer units.
    ///   - centerY: The vertical center in renderer units.
    ///   - width: The key width in standard key units.
    ///   - height: The key height in standard key units.
    ///   - rotationDegrees: The clockwise rotation in degrees.
    public init(
        centerX: Double,
        centerY: Double,
        width: Double = 1,
        height: Double = 1,
        rotationDegrees: Double = 0
    ) {
        precondition(width > 0 && height > 0, "Physical controls need positive dimensions.")
        self.centerX = centerX
        self.centerY = centerY
        self.width = width
        self.height = height
        self.rotationDegrees = rotationDegrees
    }
}
