/// The coordinate and rotation for one physical switch.
public struct PhysicalKeyPlacement: Equatable, Sendable {
    /// The horizontal coordinate of the switch center.
    public let centerX: Double

    /// The vertical coordinate of the switch center.
    public let centerY: Double

    /// The clockwise rotation of the switch, in degrees.
    public let rotationDegrees: Double

    /// The switch width in standard key units.
    public let width: Double

    /// The switch height in standard key units.
    public let height: Double

    /// Creates a physical switch placement.
    ///
    /// - Parameters:
    ///   - centerX: The horizontal coordinate of the switch center.
    ///   - centerY: The vertical coordinate of the switch center.
    ///   - rotationDegrees: The clockwise rotation of the switch, in degrees.
    ///   - width: The switch width in standard key units.
    ///   - height: The switch height in standard key units.
    init(
        centerX: Double,
        centerY: Double,
        rotationDegrees: Double,
        width: Double = 1,
        height: Double = 1
    ) {
        self.centerX = centerX
        self.centerY = centerY
        self.rotationDegrees = rotationDegrees
        self.width = width
        self.height = height
    }
}
