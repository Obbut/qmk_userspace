/// A statically typed optional keymap component.
public struct OptionalKeymap<Component: KeymapDefinition>: KeymapDefinition {
    fileprivate let component: Component?

    /// Creates an optional keymap component.
    public init(_ component: Component?) {
        self.component = component
    }

    public var layerCount: Int { component?.layerCount ?? 0 }
    public var encoderCount: Int { component?.encoderCount ?? 0 }

    public func layer(at ordinal: Int) -> KeymapLayerMetadata? {
        component?.layer(at: ordinal)
    }

    public func key(at index: Int, onLayer layerOrdinal: Int) -> Key? {
        component?.key(at: index, onLayer: layerOrdinal)
    }

    public func encoder(at ordinal: Int) -> KeymapEncoderMetadata? {
        component?.encoder(at: ordinal)
    }

    public func encoderMapping(onLayer layerOrdinal: Int, encoderAt encoderOrdinal: Int) -> On? {
        component?.encoderMapping(onLayer: layerOrdinal, encoderAt: encoderOrdinal)
    }
}
