/// The keymap-drawer coordinate and rotation for one physical switch.
struct PhysicalKeyPlacement: Equatable, Sendable {
    /// The horizontal center in the generated board coordinate space.
    let centerX: Double

    /// The vertical center in the generated board coordinate space.
    let centerY: Double

    /// The clockwise rotation used by the physical switch.
    let rotationDegrees: Double
}
