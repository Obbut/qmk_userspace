/// Composes heterogeneous firmware features with a variadic generic parameter pack.
@resultBuilder
public enum FirmwareFeatureBuilder {
    /// Collects statically typed features without existential storage at call sites.
    ///
    /// - Parameter features: The heterogeneous feature parameter pack.
    /// - Returns: The ordered feature descriptors.
    public static func buildBlock<each Feature: FirmwareFeature>(
        _ features: repeat each Feature
    ) -> FirmwareFeatures {
        var descriptors: [FirmwareFeatureDescriptor] = []
        repeat descriptors.append((each features).firmwareFeatureDescriptor)
        return FirmwareFeatures(descriptors: descriptors)
    }
}
