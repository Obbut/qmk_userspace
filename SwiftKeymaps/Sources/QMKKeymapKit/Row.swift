/// One readable group of keys inside a layout result builder.
public struct Row<Domain: KeymapDomain>: Sendable {
    /// The keys in declaration order.
    public let keys: [Key<Domain>]

    /// Creates a row from domain-typed keys.
    ///
    /// - Parameter keys: The keys in declaration order.
    public init(_ keys: Key<Domain>...) {
        self.keys = keys
    }

    /// Creates a row from a previously composed key collection.
    ///
    /// - Parameter keys: The keys in declaration order.
    public init(keys: [Key<Domain>]) {
        self.keys = keys
    }
}
