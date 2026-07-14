extension KeymapProtocol {
    /// A semantic override for a compiled QMK keycode.
    public enum KeySemantic: UInt8, Equatable, Sendable {
        /// No semantic override.
        case none = 0

        /// The macOS or Windows screenshot action.
        case screenshot = 1

        /// The Aerospace window-manager modifier chord.
        case aerospace = 2
    }
}
