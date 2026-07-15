/// Stable meaning and fallback presentation attached directly to a key action.
public struct KeySemantic: Equatable, Hashable, Sendable {
    public let id: StaticString
    public let legend: StaticString
    public let symbol: KeySymbol?

    /// Deterministic nonzero protocol-v4 content identifier.
    public var contentID: UInt16 { StaticStringContent.identifier(id) }

    public init(id: StaticString, legend: StaticString, symbol: KeySymbol? = nil) {
        precondition(id.utf8CodeUnitCount > 0, "A key semantic needs a stable identifier.")
        precondition(legend.utf8CodeUnitCount > 0, "A key semantic needs a fallback legend.")
        self.id = id
        self.legend = legend
        self.symbol = symbol
    }

    public static func == (lhs: KeySemantic, rhs: KeySemantic) -> Bool {
        StaticStringContent.equals(lhs.id, rhs.id)
            && StaticStringContent.equals(lhs.legend, rhs.legend)
            && lhs.symbol == rhs.symbol
    }

    public func hash(into hasher: inout Hasher) {
        StaticStringContent.hash(id, into: &hasher)
        StaticStringContent.hash(legend, into: &hasher)
        hasher.combine(symbol)
    }
}
