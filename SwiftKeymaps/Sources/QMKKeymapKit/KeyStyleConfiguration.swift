/// Information available while a key style resolves its portable appearance.
public struct KeyStyleConfiguration: Sendable {
    /// The QMK action being styled.
    public let keycode: QMKKeycode

    /// Creates style input for one key action.
    ///
    /// - Parameter keycode: The QMK action being styled.
    public init(keycode: QMKKeycode) {
        self.keycode = keycode
    }
}
