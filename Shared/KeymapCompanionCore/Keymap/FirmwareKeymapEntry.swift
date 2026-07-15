/// One matrix entry downloaded from keyboard firmware.
public struct FirmwareKeymapEntry: Equatable, Sendable {
    /// The compiled QMK keycode.
    public let keycode: UInt16

    /// The optional companion-specific semantic identifier.
    public let semantic: KeySemantic

    /// The firmware-assigned visual category.
    public let style: KeyStyle

    /// Creates one decoded firmware keymap entry.
    ///
    /// - Parameters:
    ///   - keycode: The compiled QMK keycode.
    ///   - semantic: The optional companion-specific semantic identifier.
    ///   - style: The firmware-assigned visual category.
    public init(keycode: UInt16, semantic: KeySemantic, style: KeyStyle) {
        self.keycode = keycode
        self.semantic = semantic
        self.style = style
    }
}
