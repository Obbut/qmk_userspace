/// The coordinate and rotation for one physical switch.
public struct PhysicalKeyPlacement: Equatable, Sendable {
    /// The horizontal coordinate of the switch center.
    public let centerX: Double

    /// The vertical coordinate of the switch center.
    public let centerY: Double

    /// The clockwise rotation of the switch, in degrees.
    public let rotationDegrees: Double

    /// Creates a physical switch placement.
    ///
    /// - Parameters:
    ///   - centerX: The horizontal coordinate of the switch center.
    ///   - centerY: The vertical coordinate of the switch center.
    ///   - rotationDegrees: The clockwise rotation of the switch, in degrees.
    public init(centerX: Double, centerY: Double, rotationDegrees: Double) {
        self.centerX = centerX
        self.centerY = centerY
        self.rotationDegrees = rotationDegrees
    }
}
