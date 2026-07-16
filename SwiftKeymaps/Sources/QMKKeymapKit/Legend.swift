/// Display metadata for a key, with an optional renderer-neutral icon.
public struct Legend: Equatable, Hashable, Sendable, ExpressibleByStringLiteral {
    public typealias StringLiteralType = StaticString

    /// The text shown when a renderer cannot or should not display the icon.
    public let label: StaticString

    /// An optional explicitly selected icon.
    public let icon: Icon?

    /// Creates a legend with optional icon presentation.
    public init(_ label: StaticString, icon: Icon? = nil) {
        self.label = label
        self.icon = icon
    }

    /// Allows ordinary string literals to remain the concise legend syntax.
    public init(stringLiteral value: StaticString) {
        self.init(value)
    }

    /// The deterministic nonzero identifier used by the firmware protocol.
    public var contentID: UInt16 {
        StaticStringContent.identifier(label, secondary: icon?.name)
    }

    public static func == (lhs: Legend, rhs: Legend) -> Bool {
        StaticStringContent.equals(lhs.label, rhs.label) && lhs.icon == rhs.icon
    }

    public func hash(into hasher: inout Hasher) {
        StaticStringContent.hash(label, into: &hasher)
        hasher.combine(icon)
    }
}

extension Legend {
    /// A portable icon identifier understood by host renderers.
    public struct Icon: Equatable, Hashable, Sendable {
        public let name: StaticString

        /// Creates a custom renderer-neutral icon identifier.
        public init(_ name: StaticString) {
            self.name = name
        }

        public static func == (lhs: Icon, rhs: Icon) -> Bool {
            StaticStringContent.equals(lhs.name, rhs.name)
        }

        public func hash(into hasher: inout Hasher) {
            StaticStringContent.hash(name, into: &hasher)
        }

        public static let camera = Icon("camera")
        public static let windowManagement = Icon("window-management")
        public static let lockedPointer = Icon("locked-pointer")
        public static let bluetooth = Icon("bluetooth")
        public static let battery = Icon("battery")
        public static let pointerButton = Icon("pointer-button")
        public static let pointer = Icon("pointer")
        public static let scroll = Icon("scroll")
        public static let browserNavigation = Icon("browser-navigation")
        public static let wireless = Icon("wireless")
    }
}
