/// A renderer-ready RGB style resolved from generated metadata.
public struct KeymapRenderStyle: Equatable, Sendable {
    /// The red color component.
    public let red: UInt8

    /// The green color component.
    public let green: UInt8

    /// The blue color component.
    public let blue: UInt8

    /// Whether the metadata fingerprint allowed this style to be resolved.
    public let isKnown: Bool

    public init(red: UInt8, green: UInt8, blue: UInt8, isKnown: Bool = true) {
        self.red = red
        self.green = green
        self.blue = blue
        self.isKnown = isKnown
    }

    /// Neutral fallback presentation.
    public static let standard = KeymapRenderStyle(red: 90, green: 90, blue: 96)
}
