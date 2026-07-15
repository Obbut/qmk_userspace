/// A renderer-neutral symbol name attached to semantic metadata.
public struct KeySymbol: Equatable, Hashable, Sendable {
    public let name: StaticString

    public init(name: StaticString) {
        self.name = name
    }

    public static func == (lhs: KeySymbol, rhs: KeySymbol) -> Bool {
        StaticStringContent.equals(lhs.name, rhs.name)
    }

    public func hash(into hasher: inout Hasher) {
        StaticStringContent.hash(name, into: &hasher)
    }

    public static let camera = KeySymbol(name: "camera")
    public static let windowManagement = KeySymbol(name: "window-management")
    public static let lockedPointer = KeySymbol(name: "locked-pointer")
    public static let bluetooth = KeySymbol(name: "bluetooth")
    public static let battery = KeySymbol(name: "battery")
    public static let pointerButton = KeySymbol(name: "pointer-button")
    public static let pointer = KeySymbol(name: "pointer")
    public static let scroll = KeySymbol(name: "scroll")
    public static let browserNavigation = KeySymbol(name: "browser-navigation")
    public static let wireless = KeySymbol(name: "wireless")
}
