/// Composes rows into layout-macro argument order without arrays.
@resultBuilder
public enum KeyRowsBuilder {
    /// Includes one row or static key sequence.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildExpression<Content: KeySequence>(_ content: Content) -> Content {
        content
    }

    /// Starts a statically typed row chain.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildPartialBlock<Content: KeySequence>(
        first content: Content
    ) -> Content {
        content
    }

    /// Appends a row without variadic-pack witness dispatch.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildPartialBlock<Accumulated: KeySequence, Next: KeySequence>(
        accumulated: Accumulated,
        next: Next
    ) -> KeySequenceGroup<Accumulated, Next> {
        KeySequenceGroup(accumulated, next)
    }

    /// Includes an optional row.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildOptional<Content: KeySequence>(
        _ content: Content?
    ) -> OptionalKeySequence<Content> {
        OptionalKeySequence(content)
    }

    /// Selects the first conditional row branch.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildEither<First: KeySequence, Second: KeySequence>(
        first content: First
    ) -> ConditionalKeySequence<First, Second> {
        ConditionalKeySequence.first(content)
    }

    /// Selects the second conditional row branch.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildEither<First: KeySequence, Second: KeySequence>(
        second content: Second
    ) -> ConditionalKeySequence<First, Second> {
        ConditionalKeySequence.second(content)
    }
}
