/// Adapts a reusable component to the concrete keymap-node protocol.
public struct KeymapComponentDefinition<Component: KeymapComponent>: KeymapDefinition {
    @usableFromInline
    internal let component: Component

    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ component: Component) {
        self.component = component
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public var layerCount: Int { component.body.layerCount }

    @_alwaysEmitIntoClient
    @inline(__always)
    public var encoderCount: Int { component.body.encoderCount }

    @_alwaysEmitIntoClient
    @inline(__always)
    public func layer(at index: Int) -> KeymapLayerMetadata? {
        component.body.layer(at: index)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public func key(at index: Int, onLayer layerIndex: Int) -> Key? {
        component.body.key(at: index, onLayer: layerIndex)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public func encoder(at index: Int) -> KeymapEncoderMetadata? {
        component.body.encoder(at: index)
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public func encoderMapping(onLayer layerIndex: Int, encoderAt index: Int) -> On? {
        component.body.encoderMapping(onLayer: layerIndex, encoderAt: index)
    }
}
