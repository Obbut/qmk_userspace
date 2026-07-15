/// A renderer-neutral symbol name attached to semantic metadata.
public struct KeySymbol: Equatable, Hashable, Sendable {
    /// The stable symbol name.
    public let name: String

    /// Creates a renderer-neutral symbol.
    ///
    /// - Parameter name: The stable symbol name.
    public init(name: String) {
        self.name = name
    }

    /// A screenshot camera.
    public static let camera = KeySymbol(name: "camera")

    /// A window-management symbol.
    public static let windowManagement = KeySymbol(name: "window-management")

    /// A locked pointer symbol.
    public static let lockedPointer = KeySymbol(name: "locked-pointer")

    /// A Bluetooth radio symbol.
    public static let bluetooth = KeySymbol(name: "bluetooth")

    /// A battery-level symbol.
    public static let battery = KeySymbol(name: "battery")

    /// A pointer button symbol.
    public static let pointerButton = KeySymbol(name: "pointer-button")

    /// A pointer movement symbol.
    public static let pointer = KeySymbol(name: "pointer")

    /// A scrolling symbol.
    public static let scroll = KeySymbol(name: "scroll")

    /// A browser-navigation symbol.
    public static let browserNavigation = KeySymbol(name: "browser-navigation")

    /// A wireless-radio symbol.
    public static let wireless = KeySymbol(name: "wireless")
}
