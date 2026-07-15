/// One readable group of keys inside a layout result builder.
public struct Row: Sendable {
    /// The keys in declaration order.
    public let keys: [Key]

    /// Creates a row from key actions.
    ///
    /// - Parameter keys: The keys in declaration order.
    public init(_ keys: Key...) {
        self.keys = keys
    }

    /// Creates a row from a previously composed key collection.
    ///
    /// - Parameter keys: The keys in declaration order.
    public init(keys: [Key]) {
        self.keys = keys
    }
}
