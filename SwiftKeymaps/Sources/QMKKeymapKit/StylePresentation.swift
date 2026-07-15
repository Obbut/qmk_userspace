/// The display information for one domain-owned visual-style identifier.
public struct Style<ID: KeyStyleID>: Equatable, Sendable {
    /// The stable style identifier.
    public let id: ID

    /// The color used by renderers and layer lighting.
    public let color: RGBColor

    /// Creates style presentation information.
    ///
    /// - Parameters:
    ///   - id: The stable style identifier.
    ///   - color: The color used by renderers and layer lighting.
    public init(_ id: ID, color: RGBColor) {
        self.id = id
        self.color = color
    }
}
