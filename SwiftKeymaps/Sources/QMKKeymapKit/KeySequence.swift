/// A statically sized sequence of key actions.
public protocol KeySequence: Sendable {
    /// The number of key actions in the sequence.
    var keyCount: Int { get }

    /// Returns the key at a sequence-relative index.
    func key(at index: Int) -> Key?
}

extension Key: KeySequence {
    public var keyCount: Int { 1 }

    public func key(at index: Int) -> Key? {
        index == 0 ? self : nil
    }
}
