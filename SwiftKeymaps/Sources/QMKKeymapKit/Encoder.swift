/// Layer-specific actions for one physical encoder.
public struct Encoder<Mappings: EncoderMappings>: KeymapDefinition {
    /// The zero-based QMK encoder index.
    public let index: Int

    /// The stable encoder identifier from the layout descriptor.
    public let id: StaticString

    /// The statically composed per-layer mappings.
    public let mappings: Mappings

    /// Creates an encoder map.
    public init(
        _ index: Int,
        id: StaticString,
        @EncoderBuilder content: () -> Mappings
    ) {
        precondition(index >= 0 && id.utf8CodeUnitCount > 0, "Encoder identifiers and indices must be valid.")
        self.index = index
        self.id = id
        mappings = content()
    }

    /// Creates an encoder from an already composed concrete mapping node.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ index: Int, id: StaticString, mappings: Mappings) {
        precondition(index >= 0 && id.utf8CodeUnitCount > 0, "Encoder identifiers and indices must be valid.")
        self.index = index
        self.id = id
        self.mappings = mappings
    }

    public var layerCount: Int { 0 }
    public var encoderCount: Int { 1 }

    public func layer(at ordinal: Int) -> KeymapLayerMetadata? { nil }

    public func key(at index: Int, onLayer layerOrdinal: Int) -> Key? { nil }

    public func encoder(at ordinal: Int) -> KeymapEncoderMetadata? {
        guard ordinal == 0 else { return nil }
        return KeymapEncoderMetadata(index: index, id: id)
    }

    public func encoderMapping(onLayer layerOrdinal: Int, encoderAt encoderOrdinal: Int) -> On? {
        guard encoderOrdinal == 0 else { return nil }
        for mappingOrdinal in 0..<mappings.mappingCount {
            guard let mapping = mappings.mapping(at: mappingOrdinal) else { continue }
            if Int(mapping.layer.rawValue) == layerOrdinal { return mapping }
        }
        return nil
    }
}
