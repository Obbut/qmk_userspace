/// Protocol constants for rotary-encoder directions.
extension KeymapProtocol {
    /// One rotary direction in the firmware encoder map.
    public enum EncoderDirection: Int, CaseIterable, Equatable, Sendable {
        /// Counterclockwise rotation.
        case counterclockwise = 0

        /// Clockwise rotation.
        case clockwise = 1
    }
}
