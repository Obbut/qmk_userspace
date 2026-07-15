/// A typed collection of semantic presentation entries.
public protocol SemanticCatalog: Sendable {
    /// The domain-owned semantic identifier type.
    associatedtype ID: KeySemanticID

    /// The catalog entries in stable declaration order.
    var entries: [Semantic<ID>] { get }
}

/// The concrete semantic catalog produced by ``SemanticCatalogBuilder``.
public struct SemanticCatalogValue<ID: KeySemanticID>: SemanticCatalog, Sendable {
    /// The catalog entries in stable declaration order.
    public let entries: [Semantic<ID>]

    /// Creates a catalog from validated entries.
    ///
    /// - Parameter entries: The catalog entries in stable declaration order.
    public init(entries: [Semantic<ID>]) {
        precondition(Set(entries.map(\.id)).count == entries.count, "Semantic IDs must be unique.")
        self.entries = entries
    }
}

/// Builds a strongly typed semantic catalog.
@resultBuilder
public enum SemanticCatalogBuilder {
    /// Combines catalog entries.
    ///
    /// - Parameter entries: The entries declared by the domain.
    /// - Returns: A concrete typed catalog.
    public static func buildBlock<ID: KeySemanticID>(
        _ entries: Semantic<ID>...
    ) -> SemanticCatalogValue<ID> {
        SemanticCatalogValue(entries: entries)
    }
}
