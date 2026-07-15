/// Composes heterogeneous executable features without existential erasure.
@resultBuilder
public enum FirmwareFeatureBuilder {
    /// Adapts one feature to a statically traversable feature definition.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildExpression<Feature: FirmwareFeature>(
        _ feature: Feature
    ) -> FirmwareFeatureDefinition<Feature> {
        FirmwareFeatureDefinition(feature)
    }

    /// Starts a statically typed feature chain.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildPartialBlock<FeatureSet: FirmwareFeatureSet>(
        first featureSet: FeatureSet
    ) -> FeatureSet {
        featureSet
    }

    /// Appends a feature without variadic-pack witness dispatch.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func buildPartialBlock<
        Accumulated: FirmwareFeatureSet,
        Next: FirmwareFeatureSet
    >(
        accumulated: Accumulated,
        next: Next
    ) -> FirmwareFeatureGroup<Accumulated, Next> {
        FirmwareFeatureGroup(accumulated, next)
    }
}
