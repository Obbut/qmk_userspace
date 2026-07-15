/// One matrix entry downloaded from keyboard firmware.
public struct FirmwareKeymapEntry: Equatable, Sendable {
    /// The compiled QMK keycode.
    public let keycode: UInt16

    /// The opaque catalog-scoped semantic identifier.
    public let semanticID: SemanticID

    /// The opaque catalog-scoped visual-style identifier.
    public let styleID: StyleID

    /// Creates one decoded firmware keymap entry.
    ///
    /// - Parameters:
    ///   - keycode: The compiled QMK keycode.
    ///   - semanticID: The catalog-scoped semantic identifier.
    ///   - styleID: The catalog-scoped visual-style identifier.
    public init(keycode: UInt16, semanticID: SemanticID, styleID: StyleID) {
        self.keycode = keycode
        self.semanticID = semanticID
        self.styleID = styleID
    }
}
