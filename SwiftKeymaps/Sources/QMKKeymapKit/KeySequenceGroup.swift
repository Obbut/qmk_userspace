/// Two statically typed key sequences composed in declaration order.
public struct KeySequenceGroup<First: KeySequence, Second: KeySequence>: KeySequence {
    @usableFromInline internal let first: First
    @usableFromInline internal let second: Second

    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ first: First, _ second: Second) {
        self.first = first
        self.second = second
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public var keyCount: Int { first.keyCount + second.keyCount }

    @_alwaysEmitIntoClient
    @inline(__always)
    public func key(at index: Int) -> Key? {
        if index < first.keyCount { return first.key(at: index) }
        return second.key(at: index - first.keyCount)
    }
}
