/// Composes statically typed keymap definitions in declaration order.
@resultBuilder
public enum Keymap {
    /// Includes one keymap component.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildExpression<Component: KeymapDefinition>(
        _ component: Component
    ) -> Component {
        component
    }

    /// Includes a reusable component while preserving its concrete body type.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildExpression<Component: KeymapComponent>(
        _ component: Component
    ) -> KeymapComponentDefinition<Component> {
        KeymapComponentDefinition(component)
    }

    /// Starts a statically typed component chain.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildPartialBlock<Component: KeymapDefinition>(
        first component: Component
    ) -> Component {
        component
    }

    /// Appends a component without variadic-pack witness dispatch.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildPartialBlock<
        Accumulated: KeymapDefinition,
        Next: KeymapDefinition
    >(
        accumulated: Accumulated,
        next: Next
    ) -> KeymapGroup<Accumulated, Next> {
        KeymapGroup(accumulated, next)
    }

    /// Includes an optional component.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildOptional<Component: KeymapDefinition>(
        _ component: Component?
    ) -> OptionalKeymap<Component> {
        OptionalKeymap(component)
    }

    /// Selects the first conditional branch.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildEither<First: KeymapDefinition, Second: KeymapDefinition>(
        first component: First
    ) -> ConditionalKeymap<First, Second> {
        ConditionalKeymap<First, Second>.first(component)
    }

    /// Selects the second conditional branch.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildEither<First: KeymapDefinition, Second: KeymapDefinition>(
        second component: Second
    ) -> ConditionalKeymap<First, Second> {
        ConditionalKeymap<First, Second>.second(component)
    }
}
