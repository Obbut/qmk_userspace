/// The display information for one domain-owned semantic identifier.
public struct Semantic<ID: KeySemanticID>: Equatable, Sendable {
    /// The stable semantic identifier.
    public let id: ID

    /// The fallback text shown by renderers.
    public let legend: String

    /// The optional renderer-neutral symbol.
    public let symbol: KeySymbol?

    /// Creates semantic presentation information.
    ///
    /// - Parameters:
    ///   - id: The stable semantic identifier.
    ///   - legend: The fallback text shown by renderers.
    ///   - symbol: The optional renderer-neutral symbol.
    public init(_ id: ID, legend: String, symbol: KeySymbol? = nil) {
        self.id = id
        self.legend = legend
        self.symbol = symbol
    }
}
