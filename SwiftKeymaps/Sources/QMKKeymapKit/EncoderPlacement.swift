/// A physical encoder represented by the companion protocol.
public struct EncoderPlacement: Equatable, Sendable {
    /// The stable encoder identifier.
    public let id: String

    /// The zero-based encoder index used by QMK.
    public let index: Int

    /// The renderer geometry.
    public let geometry: PhysicalKeyPlacement

    /// The optional matrix coordinate for encoder press.
    public let pressPosition: MatrixPosition?

    /// Creates a physical encoder descriptor.
    ///
    /// - Parameters:
    ///   - id: The stable encoder identifier.
    ///   - index: The zero-based encoder index used by QMK.
    ///   - geometry: The renderer geometry.
    ///   - pressPosition: The optional matrix coordinate for encoder press.
    public init(
        id: String,
        index: Int,
        geometry: PhysicalKeyPlacement,
        pressPosition: MatrixPosition? = nil
    ) {
        precondition(!id.isEmpty && index >= 0, "Encoder identifiers and indices must be valid.")
        self.id = id
        self.index = index
        self.geometry = geometry
        self.pressPosition = pressPosition
    }
}
