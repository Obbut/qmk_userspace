/// Stable meaning and fallback presentation attached directly to a key action.
public struct KeySemantic: Equatable, Hashable, Sendable {
    /// The globally stable identifier used to recognize this meaning.
    public let id: String

    /// The fallback text shown when no platform-specific presentation exists.
    public let legend: String

    /// An optional renderer-neutral symbol.
    public let symbol: KeySymbol?

    /// Creates semantic metadata for a key action.
    ///
    /// - Parameters:
    ///   - id: A stable reverse-DNS identifier.
    ///   - legend: The fallback text shown by renderers.
    ///   - symbol: An optional renderer-neutral symbol.
    public init(id: String, legend: String, symbol: KeySymbol? = nil) {
        precondition(!id.isEmpty, "A key semantic needs a stable identifier.")
        precondition(!legend.isEmpty, "A key semantic needs a fallback legend.")
        self.id = id
        self.legend = legend
        self.symbol = symbol
    }
}
