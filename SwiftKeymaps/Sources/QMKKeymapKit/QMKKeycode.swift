/// The exact 16-bit keycode consumed by QMK's key-processing ABI.
public struct QMKKeycode: Equatable, Hashable, Sendable {
    /// The numeric QMK ABI value.
    public let rawValue: UInt16

    /// Creates a keycode from its QMK ABI value.
    ///
    /// - Parameter rawValue: The exact value QMK consumes.
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
}
