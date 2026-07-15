/// A statically typed optional encoder mapping.
public struct OptionalEncoderMapping<Mapping: EncoderMappings>: EncoderMappings {
    fileprivate let mapping: Mapping?

    /// Creates an optional mapping.
    public init(_ mapping: Mapping?) {
        self.mapping = mapping
    }

    public var mappingCount: Int { mapping?.mappingCount ?? 0 }

    public func mapping(at ordinal: Int) -> On? {
        mapping?.mapping(at: ordinal)
    }
}
