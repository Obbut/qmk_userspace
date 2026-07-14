/// One rotary direction in the firmware encoder map.
enum EncoderDirection: Int, CaseIterable, Equatable, Sendable {
    /// Counter-clockwise rotation.
    case counterClockwise = 0

    /// Clockwise rotation.
    case clockwise = 1
}
