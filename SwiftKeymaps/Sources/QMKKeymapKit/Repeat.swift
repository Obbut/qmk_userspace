/// Repeats one key without allocating a collection.
public struct Repeat: KeySequence {
    /// The repeated key.
    public let key: Key

    /// The number of repetitions.
    public let count: Int

    /// Creates a repeated key sequence.
    public init(_ key: Key, count: Int) {
        precondition(count >= 0, "A repeat count cannot be negative.")
        self.key = key
        self.count = count
    }

    public var keyCount: Int { count }

    public func key(at index: Int) -> Key? {
        index >= 0 && index < count ? key : nil
    }
}
