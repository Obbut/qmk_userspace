import QMKKeymapKit

/// A static keymap materialized and validated for host tooling.
public struct KeymapSpec: KeymapSpecification, Sendable {
    /// The stable keymap identifier.
    public let id: String

    /// The keyboard layout and physical geometry.
    public let layout: LayoutDescriptor

    /// The layers in firmware index order.
    public let layers: [ResolvedLayer]

    /// The physical encoders in QMK index order.
    public let encoders: [ResolvedEncoder]

    /// Materializes declarations produced by ``Keymap``.
    public init<Definition: KeymapDefinition>(
        id: String,
        layout: LayoutDescriptor,
        @Keymap content: () -> Definition
    ) {
        self.init(id: id, layout: layout, keymap: content())
    }

    /// Materializes and validates a statically typed keymap definition.
    public init<Definition: KeymapDefinition>(
        id: String,
        layout: LayoutDescriptor,
        keymap: Definition
    ) {
        precondition(!id.isEmpty, "A keymap identifier cannot be empty.")
        precondition(keymap.layerCount > 0, "A keymap must declare at least one layer.")

        var resolvedLayers: [ResolvedLayer] = []
        for layerOrdinal in 0..<keymap.layerCount {
            guard let metadata = keymap.layer(at: layerOrdinal) else {
                preconditionFailure("Every declared layer must provide metadata.")
            }
            var keys: [Key] = []
            keys.reserveCapacity(layout.keyCount)
            for keyIndex in 0..<layout.keyCount {
                guard let key = keymap.key(at: keyIndex, onLayer: layerOrdinal) else {
                    preconditionFailure(
                        "Every layer must provide exactly \(layout.keyCount) layout arguments."
                    )
                }
                keys.append(key)
            }
            precondition(
                keymap.key(at: layout.keyCount, onLayer: layerOrdinal) == nil,
                "Every layer must provide exactly \(layout.keyCount) layout arguments."
            )
            resolvedLayers.append(
                ResolvedLayer(
                    id: metadata.id,
                    name: StaticStringContent.string(metadata.name),
                    showsHUD: metadata.showsHUD,
                    keys: keys
                )
            )
        }

        precondition(
            resolvedLayers.map(\.id.rawValue) == Array(0..<UInt8(resolvedLayers.count)),
            "Layers must be unique, contiguous, and declared in firmware order."
        )

        var resolvedEncoders: [ResolvedEncoder] = []
        for encoderOrdinal in 0..<keymap.encoderCount {
            guard let metadata = keymap.encoder(at: encoderOrdinal) else {
                preconditionFailure("Every declared encoder must provide metadata.")
            }
            var mappings: [On] = []
            for layerOrdinal in 0..<resolvedLayers.count {
                guard let mapping = keymap.encoderMapping(
                    onLayer: layerOrdinal,
                    encoderAt: encoderOrdinal
                ) else {
                    preconditionFailure("Every encoder needs one mapping for every layer.")
                }
                mappings.append(mapping)
            }
            resolvedEncoders.append(
                ResolvedEncoder(
                    index: metadata.index,
                    id: StaticStringContent.string(metadata.id),
                    mappings: mappings
                )
            )
        }

        precondition(
            resolvedEncoders.map(\.index).sorted() == layout.encoders.map(\.index).sorted(),
            "The declared encoders must match the layout descriptor."
        )

        self.id = id
        self.layout = layout
        layers = resolvedLayers
        encoders = resolvedEncoders.sorted { $0.index < $1.index }
    }
}
