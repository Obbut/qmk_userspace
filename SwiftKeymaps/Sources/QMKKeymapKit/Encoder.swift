/// The complete mapping for one physical encoder.
public struct Encoder<Domain: KeymapDomain>: Sendable {
    /// The zero-based QMK encoder index.
    public let index: Int

    /// The stable encoder identifier from the layout descriptor.
    public let id: String

    /// The per-layer mappings.
    public let mappings: [On<Domain>]

    /// Creates an encoder map.
    ///
    /// - Parameters:
    ///   - index: The zero-based QMK encoder index.
    ///   - id: The stable encoder identifier from the layout descriptor.
    ///   - content: The per-layer mappings.
    public init(
        _ index: Int,
        id: String,
        @EncoderBuilder<Domain> content: () -> [On<Domain>]
    ) {
        precondition(index >= 0 && !id.isEmpty, "Encoder identifiers and indices must be valid.")
        self.index = index
        self.id = id
        mappings = content()
    }
}
