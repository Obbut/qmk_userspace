/// The uninhabited context used by layers whose content captures no values.
public enum StatelessLayerContext: Sendable {}

#if hasFeature(Embedded)
public typealias StatelessLayerContent<Content> =
    @convention(thin) @Sendable () -> Content

public typealias ContextualLayerContent<Context, Content> =
    @convention(thin) @Sendable (Context) -> Content
#else
public typealias StatelessLayerContent<Content> = @Sendable () -> Content

public typealias ContextualLayerContent<Context, Content> = @Sendable (Context) -> Content
#endif

@usableFromInline
internal enum LayerContentFactory<Content: KeySequence, Context: Sendable>: Sendable {
    case stateless(StatelessLayerContent<Content>)
    case contextual(Context, ContextualLayerContent<Context, Content>)
}

/// A statically typed keymap layer in layout-macro argument order.
public struct Layer<Content: KeySequence, Context: Sendable>: KeymapDefinition {
    /// The stable layer identifier.
    public let id: LayerID

    /// The name shown by companions and previews.
    public let name: StaticString

    /// Whether activating this layer should show the transient HUD.
    public let showsHUD: Bool

    /// Whether the containing keymap assigns the ID from declaration order.
    @usableFromInline
    internal let usesDeclarationOrdinal: Bool

    /// Produces the layer's statically composed keys only when it is traversed.
    @usableFromInline
    internal let content: LayerContentFactory<Content, Context>

    /// Creates a layer from readable rows.
    public init<ID: FirmwareLayerID>(
        _ id: ID,
        name: StaticString,
        showsHUD: Bool = false,
        @KeyRowsBuilder content: @escaping StatelessLayerContent<Content>
    ) where Context == StatelessLayerContext {
        self.id = id.qmkLayerID
        self.name = name
        self.showsHUD = showsHUD
        usesDeclarationOrdinal = false
        self.content = .stateless(content)
    }

    /// Creates a layer whose ID is inferred from its declaration order.
    public init(
        name: StaticString,
        showsHUD: Bool = false,
        @KeyRowsBuilder content: @escaping StatelessLayerContent<Content>
    ) where Context == StatelessLayerContext {
        id = LayerID(rawValue: 0)
        self.name = name
        self.showsHUD = showsHUD
        usesDeclarationOrdinal = true
        self.content = .stateless(content)
    }

    /// Creates a layer whose static body depends on one explicitly stored value.
    public init<ID: FirmwareLayerID>(
        _ id: ID,
        name: StaticString,
        showsHUD: Bool = false,
        context: Context,
        @KeyRowsBuilder content: @escaping ContextualLayerContent<Context, Content>
    ) {
        self.id = id.qmkLayerID
        self.name = name
        self.showsHUD = showsHUD
        usesDeclarationOrdinal = false
        self.content = .contextual(context, content)
    }

    /// Creates a contextual layer whose ID is inferred from declaration order.
    public init(
        name: StaticString,
        showsHUD: Bool = false,
        context: Context,
        @KeyRowsBuilder content: @escaping ContextualLayerContent<Context, Content>
    ) {
        id = LayerID(rawValue: 0)
        self.name = name
        self.showsHUD = showsHUD
        usesDeclarationOrdinal = true
        self.content = .contextual(context, content)
    }

    public var layerCount: Int { 1 }
    public var encoderCount: Int { 0 }

    public func layer(at ordinal: Int) -> KeymapLayerMetadata? {
        guard ordinal == 0 else { return nil }
        if usesDeclarationOrdinal {
            return KeymapLayerMetadata(automaticName: name, showsHUD: showsHUD)
        }
        return KeymapLayerMetadata(id: id, name: name, showsHUD: showsHUD)
    }

    public func key(at index: Int, onLayer layerOrdinal: Int) -> Key? {
        guard layerOrdinal == 0 else { return nil }
        switch content {
        case let .stateless(makeContent):
            return makeContent().key(at: index)
        case let .contextual(context, makeContent):
            return makeContent(context).key(at: index)
        }
    }

    public func encoder(at ordinal: Int) -> KeymapEncoderMetadata? { nil }

    public func encoderMapping(onLayer layerOrdinal: Int, encoderAt encoderOrdinal: Int) -> On? {
        nil
    }
}
