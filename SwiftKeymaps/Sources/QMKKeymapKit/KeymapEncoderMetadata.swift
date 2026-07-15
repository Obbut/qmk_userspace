/// Host-readable metadata for one statically composed encoder.
public struct KeymapEncoderMetadata: Sendable {
    /// The zero-based QMK encoder index.
    public let index: Int

    /// The stable encoder identifier from the layout descriptor.
    public let id: StaticString

    /// Creates encoder metadata.
    public init(index: Int, id: StaticString) {
        self.index = index
        self.id = id
    }
}
