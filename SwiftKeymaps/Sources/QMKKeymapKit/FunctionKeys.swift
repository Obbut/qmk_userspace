/// A consecutive range of styled QMK function keys.
public struct FunctionKeys<Style: KeyStyle>: KeySequence {
    fileprivate let first: Int
    fileprivate let last: Int
    fileprivate let style: Style

    /// Creates a consecutive function-key range.
    public init(_ range: ClosedRange<Int>, style: Style) {
        precondition(
            range.lowerBound >= 1 && range.upperBound <= 24,
            "QMK function keys are limited to F1...F24."
        )
        first = range.lowerBound
        last = range.upperBound
        self.style = style
    }

    public var keyCount: Int { last - first + 1 }

    public func key(at index: Int) -> Key? {
        guard index >= 0 && index < keyCount else { return nil }
        return Key.function(first + index).style(style)
    }
}
