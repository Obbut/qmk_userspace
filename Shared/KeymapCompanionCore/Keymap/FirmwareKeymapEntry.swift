/// One matrix entry downloaded from keyboard firmware.
public struct FirmwareKeymapEntry: Equatable, Sendable {
    /// The compiled QMK keycode.
    public let keycode: UInt16

    /// The generated legend identifier.
    public let legendID: LegendID

    /// The generated style identifier.
    public let styleID: StyleID

    /// Creates one decoded firmware keymap entry.
    ///
    /// - Parameters:
    ///   - keycode: The compiled QMK keycode.
    ///   - legendID: The generated legend identifier.
    ///   - styleID: The generated style identifier.
    public init(keycode: UInt16, legendID: LegendID, styleID: StyleID) {
        self.keycode = keycode
        self.legendID = legendID
        self.styleID = styleID
    }
}
