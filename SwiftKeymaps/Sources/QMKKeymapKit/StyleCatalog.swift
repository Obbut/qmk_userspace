/// A typed collection of visual-style presentation entries.
public protocol StyleCatalog: Sendable {
    /// The domain-owned style identifier type.
    associatedtype ID: KeyStyleID

    /// The catalog entries in stable declaration order.
    var entries: [Style<ID>] { get }
}

/// The concrete style catalog produced by ``StyleCatalogBuilder``.
public struct StyleCatalogValue<ID: KeyStyleID>: StyleCatalog, Sendable {
    /// The catalog entries in stable declaration order.
    public let entries: [Style<ID>]

    /// Creates a catalog from validated entries.
    ///
    /// - Parameter entries: The catalog entries in stable declaration order.
    public init(entries: [Style<ID>]) {
        precondition(Set(entries.map(\.id)).count == entries.count, "Style IDs must be unique.")
        self.entries = entries
    }
}

/// Builds a strongly typed visual-style catalog.
@resultBuilder
public enum StyleCatalogBuilder {
    /// Combines catalog entries.
    ///
    /// - Parameter entries: The entries declared by the domain.
    /// - Returns: A concrete typed catalog.
    public static func buildBlock<ID: KeyStyleID>(
        _ entries: Style<ID>...
    ) -> StyleCatalogValue<ID> {
        StyleCatalogValue(entries: entries)
    }
}
