/// One selected branch of a statically typed key-sequence conditional.
public enum ConditionalKeySequence<First: KeySequence, Second: KeySequence>: KeySequence {
    case first(First)
    case second(Second)

    public var keyCount: Int {
        switch self {
        case let .first(content): content.keyCount
        case let .second(content): content.keyCount
        }
    }

    public func key(at index: Int) -> Key? {
        switch self {
        case let .first(content): content.key(at: index)
        case let .second(content): content.key(at: index)
        }
    }
}
