/// Two statically typed keymap components composed in declaration order.
public struct KeymapGroup<First: KeymapDefinition, Second: KeymapDefinition>: KeymapDefinition {
    @usableFromInline internal let first: First
    @usableFromInline internal let second: Second

    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ first: First, _ second: Second) {
        self.first = first
        self.second = second
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public var layerCount: Int { first.layerCount + second.layerCount }

    @_alwaysEmitIntoClient
    @inline(__always)
    public var encoderCount: Int { first.encoderCount + second.encoderCount }

    @_alwaysEmitIntoClient
    @inline(__always)
    public func layer(at ordinal: Int) -> KeymapLayerMetadata? {
        let metadata: KeymapLayerMetadata?
        if ordinal < first.layerCount {
            metadata = first.layer(at: ordinal)
        } else {
            metadata = second.layer(at: ordinal - first.layerCount)
        }
        return metadata?.resolvingDeclarationOrdinal(ordinal)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public func key(at index: Int, onLayer layerOrdinal: Int) -> Key? {
        if layerOrdinal < first.layerCount {
            return first.key(at: index, onLayer: layerOrdinal)
        }
        return second.key(at: index, onLayer: layerOrdinal - first.layerCount)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public func encoder(at ordinal: Int) -> KeymapEncoderMetadata? {
        if ordinal < first.encoderCount { return first.encoder(at: ordinal) }
        return second.encoder(at: ordinal - first.encoderCount)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public func encoderMapping(onLayer layerOrdinal: Int, encoderAt encoderOrdinal: Int) -> On? {
        if encoderOrdinal < first.encoderCount {
            return first.encoderMapping(onLayer: layerOrdinal, encoderAt: encoderOrdinal)
        }
        return second.encoderMapping(
            onLayer: layerOrdinal,
            encoderAt: encoderOrdinal - first.encoderCount
        )
    }
}
