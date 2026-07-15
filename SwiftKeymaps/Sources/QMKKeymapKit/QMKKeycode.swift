/// A QMK keycode represented by its C ABI expression and optional HID value.
public struct QMKKeycode: Equatable, Hashable, Sendable {
    /// The C expression emitted at the QMK ABI boundary.
    public let cExpression: String

    /// The basic HID value used by host previews when it is known statically.
    public let hidValue: UInt16?

    /// Creates a QMK keycode expression.
    ///
    /// - Parameters:
    ///   - cExpression: The C expression emitted at the QMK ABI boundary.
    ///   - hidValue: The basic HID value used by host previews, if known.
    public init(cExpression: String, hidValue: UInt16? = nil) {
        precondition(!cExpression.isEmpty, "A QMK keycode expression cannot be empty.")
        self.cExpression = cExpression
        self.hidValue = hidValue
    }
}
