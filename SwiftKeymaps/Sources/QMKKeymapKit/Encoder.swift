/// Layer-specific actions for one physical encoder.
public struct Encoder: Sendable {
    /// The zero-based QMK encoder index.
    public let index: Int

    /// The stable encoder identifier from the layout descriptor.
    public let id: String

    /// The per-layer mappings.
    public let mappings: [On]

    /// Creates an encoder map.
    ///
    /// - Parameters:
    ///   - index: The zero-based QMK encoder index.
    ///   - id: The stable encoder identifier from the layout descriptor.
    ///   - content: The per-layer mappings.
    public init(
        _ index: Int,
        id: String,
        @EncoderBuilder content: () -> [On]
    ) {
        precondition(index >= 0 && !id.isEmpty, "Encoder identifiers and indices must be valid.")
        self.index = index
        self.id = id
        mappings = content()
    }
}
