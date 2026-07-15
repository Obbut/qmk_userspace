/// Host-readable metadata for one statically composed layer.
public struct KeymapLayerMetadata: Sendable {
    /// The stable layer identifier.
    public let id: LayerID

    /// The name shown by companions and previews.
    public let name: StaticString

    /// Whether activating this layer should show the transient HUD.
    public let showsHUD: Bool

    /// Whether composition should derive the identifier from declaration order.
    @usableFromInline
    internal let usesDeclarationOrdinal: Bool

    /// Creates layer metadata.
    public init(id: LayerID, name: StaticString, showsHUD: Bool) {
        self.id = id
        self.name = name
        self.showsHUD = showsHUD
        usesDeclarationOrdinal = false
    }

    /// Creates metadata whose identifier is resolved by its containing keymap.
    @usableFromInline
    internal init(automaticName name: StaticString, showsHUD: Bool) {
        id = LayerID(rawValue: 0)
        self.name = name
        self.showsHUD = showsHUD
        usesDeclarationOrdinal = true
    }

    /// Resolves an inferred identifier while preserving explicitly supplied IDs.
    @usableFromInline
    @inline(__always)
    internal func resolvingDeclarationOrdinal(_ ordinal: Int) -> KeymapLayerMetadata {
        guard usesDeclarationOrdinal else { return self }
        return KeymapLayerMetadata(
            id: LayerID(rawValue: UInt8(truncatingIfNeeded: ordinal)),
            name: name,
            showsHUD: showsHUD,
            usesDeclarationOrdinal: true
        )
    }

    /// Creates metadata while retaining its declaration-order resolution marker.
    @usableFromInline
    internal init(
        id: LayerID,
        name: StaticString,
        showsHUD: Bool,
        usesDeclarationOrdinal: Bool
    ) {
        self.id = id
        self.name = name
        self.showsHUD = showsHUD
        self.usesDeclarationOrdinal = usesDeclarationOrdinal
    }
}
