/// Renderer presentation resolved from generated style metadata.
public struct ResolvedKeyStyle: Equatable, Sendable {
    /// The style identifier supplied by firmware.
    public let id: StyleID

    /// The red color component.
    public let red: UInt8

    /// The green color component.
    public let green: UInt8

    /// The blue color component.
    public let blue: UInt8

    /// Whether the metadata fingerprint allowed the identifier to be resolved.
    public let isKnown: Bool

    /// Creates resolved style presentation.
    ///
    /// - Parameters:
    ///   - id: The opaque firmware style identifier.
    ///   - red: The red color component.
    ///   - green: The green color component.
    ///   - blue: The blue color component.
    ///   - isKnown: Whether the host recognized the style.
    public init(
        id: StyleID,
        red: UInt8,
        green: UInt8,
        blue: UInt8,
        isKnown: Bool
    ) {
        self.id = id
        self.red = red
        self.green = green
        self.blue = blue
        self.isKnown = isKnown
    }

    /// Neutral presentation used when no style metadata is available.
    public static let standard = ResolvedKeyStyle(
        id: .standard,
        red: 90,
        green: 90,
        blue: 96,
        isKnown: true
    )
}
