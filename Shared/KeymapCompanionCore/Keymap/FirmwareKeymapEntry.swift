/// One matrix entry downloaded from keyboard firmware.
public struct FirmwareKeymapEntry: Equatable, Sendable {
    /// The compiled QMK keycode.
    public let keycode: UInt16

    /// The generated semantic identifier.
    public let semanticID: SemanticID

    /// The generated style identifier.
    public let styleID: StyleID

    /// Creates one decoded firmware keymap entry.
    ///
    /// - Parameters:
    ///   - keycode: The compiled QMK keycode.
    ///   - semanticID: The generated semantic identifier.
    ///   - styleID: The generated style identifier.
    public init(keycode: UInt16, semanticID: SemanticID, styleID: StyleID) {
        self.keycode = keycode
        self.semanticID = semanticID
        self.styleID = styleID
    }
}
