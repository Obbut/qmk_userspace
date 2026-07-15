import QMKKeymapKit

/// A host-side encoder materialized from a static keymap definition.
public struct ResolvedEncoder: Sendable {
    /// The zero-based QMK encoder index.
    public let index: Int

    /// The stable encoder identifier.
    public let id: String

    /// The per-layer action mappings.
    public let mappings: [On]

    /// Creates a resolved encoder.
    public init(index: Int, id: String, mappings: [On]) {
        self.index = index
        self.id = id
        self.mappings = mappings
    }
}
