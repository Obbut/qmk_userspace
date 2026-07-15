/// One selected branch of a statically typed keymap conditional.
public enum ConditionalKeymap<First: KeymapDefinition, Second: KeymapDefinition>: KeymapDefinition {
    case first(First)
    case second(Second)

    public var layerCount: Int {
        switch self {
        case let .first(component): component.layerCount
        case let .second(component): component.layerCount
        }
    }

    public var encoderCount: Int {
        switch self {
        case let .first(component): component.encoderCount
        case let .second(component): component.encoderCount
        }
    }

    public func layer(at ordinal: Int) -> KeymapLayerMetadata? {
        switch self {
        case let .first(component): component.layer(at: ordinal)
        case let .second(component): component.layer(at: ordinal)
        }
    }

    public func key(at index: Int, onLayer layerOrdinal: Int) -> Key? {
        switch self {
        case let .first(component): component.key(at: index, onLayer: layerOrdinal)
        case let .second(component): component.key(at: index, onLayer: layerOrdinal)
        }
    }

    public func encoder(at ordinal: Int) -> KeymapEncoderMetadata? {
        switch self {
        case let .first(component): component.encoder(at: ordinal)
        case let .second(component): component.encoder(at: ordinal)
        }
    }

    public func encoderMapping(onLayer layerOrdinal: Int, encoderAt encoderOrdinal: Int) -> On? {
        switch self {
        case let .first(component):
            component.encoderMapping(onLayer: layerOrdinal, encoderAt: encoderOrdinal)
        case let .second(component):
            component.encoderMapping(onLayer: layerOrdinal, encoderAt: encoderOrdinal)
        }
    }
}
