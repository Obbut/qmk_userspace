import QMKKeymapKit

/// Exposes the shared layers through Embedded Swift's concrete keymap traversal API.
extension SharedHalcyonLayers: KeymapDefinition {
    public var layerCount: Int { 5 }

    public var encoderCount: Int { 0 }

    public func layer(at ordinal: Int) -> KeymapLayerMetadata? {
        switch ordinal {
        case 0: Self.baseLayer(layout: layout).layer(at: 0)
        case 1: Self.qwertyLayer(layout: layout).layer(at: 0)
        case 2: Self.lowerLayer(layout: layout).layer(at: 0)
        case 3: Self.raiseLayer(layout: layout).layer(at: 0)
        case 4: Self.functionLayer(layout: layout).layer(at: 0)
        default: nil
        }
    }

    public func key(at index: Int, onLayer layerOrdinal: Int) -> Key? {
        switch layerOrdinal {
        case 0: Self.baseLayer(layout: layout).key(at: index, onLayer: 0)
        case 1: Self.qwertyLayer(layout: layout).key(at: index, onLayer: 0)
        case 2: Self.lowerLayer(layout: layout).key(at: index, onLayer: 0)
        case 3: Self.raiseLayer(layout: layout).key(at: index, onLayer: 0)
        case 4: Self.functionLayer(layout: layout).key(at: index, onLayer: 0)
        default: nil
        }
    }

    public func encoder(at ordinal: Int) -> KeymapEncoderMetadata? {
        nil
    }

    public func encoderMapping(onLayer layerOrdinal: Int, encoderAt encoderOrdinal: Int) -> On? {
        nil
    }
}
