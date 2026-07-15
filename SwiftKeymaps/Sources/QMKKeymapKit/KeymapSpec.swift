/// A keymap validated against its identity and physical layout.
public struct KeymapSpec: KeymapSpecification, Sendable {
    /// The stable keymap identifier.
    public let id: String

    /// The keyboard layout and physical geometry.
    public let layout: LayoutDescriptor

    /// The layers in firmware index order.
    public let layers: [Layer]

    /// The physical encoders in QMK index order.
    public let encoders: [Encoder]

    /// Validates declarations produced by ``KeymapBuilder``.
    ///
    /// - Parameters:
    ///   - id: The stable keymap identifier.
    ///   - layout: The keyboard layout and physical geometry.
    ///   - content: The layer, encoder, and shared-component declarations.
    public init(
        id: String,
        layout: LayoutDescriptor,
        @KeymapBuilder content: () -> Keymap
    ) {
        self.init(id: id, layout: layout, keymap: content())
    }

    /// Validates a keymap builder result against its physical layout.
    ///
    /// - Parameters:
    ///   - id: The stable keymap identifier.
    ///   - layout: The keyboard layout and physical geometry.
    ///   - keymap: Layer and encoder declarations in source order.
    public init(id: String, layout: LayoutDescriptor, keymap: Keymap) {
        let elements = keymap.elements
        let layers = elements.compactMap { element -> Layer? in
            guard case let .layer(layer) = element else { return nil }
            return layer
        }
        let encoders = elements.compactMap { element -> Encoder? in
            guard case let .encoder(encoder) = element else { return nil }
            return encoder
        }

        precondition(!id.isEmpty, "A keymap identifier cannot be empty.")
        precondition(!layers.isEmpty, "A keymap must declare at least one layer.")
        precondition(
            layers.map(\.id.rawValue) == Array(0..<UInt8(layers.count)),
            "Layers must be unique, contiguous, and declared in firmware order."
        )
        precondition(
            layers.allSatisfy { $0.keys.count == layout.keyCount },
            "Every layer must provide exactly \(layout.keyCount) layout arguments."
        )
        precondition(
            encoders.map(\.index).sorted() == layout.encoders.map(\.index).sorted(),
            "The declared encoders must match the layout descriptor."
        )
        precondition(
            encoders.allSatisfy { encoder in
                Set(encoder.mappings.map(\.layer)).count == layers.count
                    && Set(encoder.mappings.map(\.layer)) == Set(layers.map(\.id))
            },
            "Every encoder needs exactly one mapping for every layer."
        )

        self.id = id
        self.layout = layout
        self.layers = layers
        self.encoders = encoders.sorted { $0.index < $1.index }
    }
}
