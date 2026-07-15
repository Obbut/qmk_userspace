/// Information available while a key style resolves its portable appearance.
public struct KeyStyleConfiguration: Sendable {
    /// The QMK action being styled.
    public let keycode: QMKKeycode

    /// Optional semantic metadata attached to the action.
    public let semantic: KeySemantic?

    /// Creates style input for one key action.
    ///
    /// - Parameters:
    ///   - keycode: The QMK action being styled.
    ///   - semantic: Optional semantic metadata attached to the action.
    public init(keycode: QMKKeycode, semantic: KeySemantic?) {
        self.keycode = keycode
        self.semantic = semantic
    }
}
