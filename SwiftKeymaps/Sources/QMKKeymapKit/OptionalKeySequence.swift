/// A statically typed optional sequence of keys.
public struct OptionalKeySequence<Content: KeySequence>: KeySequence {
    fileprivate let content: Content?

    /// Creates an optional sequence.
    public init(_ content: Content?) {
        self.content = content
    }

    public var keyCount: Int { content?.keyCount ?? 0 }

    public func key(at index: Int) -> Key? {
        content?.key(at: index)
    }
}
