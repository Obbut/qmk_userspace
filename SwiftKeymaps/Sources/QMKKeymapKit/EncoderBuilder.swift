/// Builds a statically typed per-layer encoder map.
@resultBuilder
public enum EncoderBuilder {
    /// Includes one encoder mapping.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildExpression<Mapping: EncoderMappings>(
        _ mapping: Mapping
    ) -> Mapping {
        mapping
    }

    /// Starts a statically typed mapping chain.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildPartialBlock<Mapping: EncoderMappings>(
        first mapping: Mapping
    ) -> Mapping {
        mapping
    }

    /// Appends a mapping without variadic-pack witness dispatch.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildPartialBlock<Accumulated: EncoderMappings, Next: EncoderMappings>(
        accumulated: Accumulated,
        next: Next
    ) -> EncoderMappingGroup<Accumulated, Next> {
        EncoderMappingGroup(accumulated, next)
    }

    /// Includes an optional encoder mapping.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildOptional<Mapping: EncoderMappings>(
        _ mapping: Mapping?
    ) -> OptionalEncoderMapping<Mapping> {
        OptionalEncoderMapping(mapping)
    }

    /// Selects the first conditional mapping branch.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildEither<First: EncoderMappings, Second: EncoderMappings>(
        first mapping: First
    ) -> ConditionalEncoderMappings<First, Second> {
        ConditionalEncoderMappings.first(mapping)
    }

    /// Selects the second conditional mapping branch.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildEither<First: EncoderMappings, Second: EncoderMappings>(
        second mapping: Second
    ) -> ConditionalEncoderMappings<First, Second> {
        ConditionalEncoderMappings.second(mapping)
    }
}
