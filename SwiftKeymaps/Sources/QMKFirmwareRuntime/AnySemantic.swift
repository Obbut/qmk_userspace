import QMKKeymapKit

/// A domain-erased semantic presentation used by host tooling.
public struct AnySemantic: Equatable, Sendable {
    /// The stable catalog-scoped identifier.
    public let id: UInt16

    /// The fallback renderer legend.
    public let legend: String

    /// The optional renderer-neutral symbol name.
    public let symbolName: String?

    /// Erases a domain-typed semantic presentation.
    ///
    /// - Parameter semantic: The presentation to erase.
    public init<ID: KeySemanticID>(_ semantic: Semantic<ID>) {
        id = semantic.id.rawValue
        legend = semantic.legend
        symbolName = semantic.symbol?.name
    }
}
