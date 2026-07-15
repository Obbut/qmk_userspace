/// Builds the per-layer map for one encoder.
@resultBuilder
public enum EncoderBuilder<Domain: KeymapDomain> {
    /// Combines encoder mappings in declaration order.
    ///
    /// - Parameter mappings: The layer-specific mappings.
    /// - Returns: The mappings in declaration order.
    /// Includes an optional encoder mapping.
    ///
    /// - Parameter component: The optional mapping.
    /// - Returns: The mapping or an empty sequence.
    public static func buildOptional(_ component: [On<Domain>]?) -> [On<Domain>] {
        component ?? []
    }

    /// Flattens mapping components.
    ///
    /// - Parameter components: The mapping components.
    /// - Returns: Mappings in declaration order.
    public static func buildBlock(_ components: [On<Domain>]...) -> [On<Domain>] {
        components.flatMap { $0 }
    }

    /// Converts one mapping into a builder component.
    ///
    /// - Parameter expression: The mapping to include.
    /// - Returns: A single-mapping component.
    public static func buildExpression(_ expression: On<Domain>) -> [On<Domain>] {
        [expression]
    }
}
