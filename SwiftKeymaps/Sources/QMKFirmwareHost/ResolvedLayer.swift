import QMKKeymapKit

/// A host-side layer materialized from a static keymap definition.
public struct ResolvedLayer: Sendable {
    /// The stable layer identifier.
    public let id: LayerID

    /// The user-facing layer name.
    public let name: String

    /// Whether this layer should show the transient HUD.
    public let showsHUD: Bool

    /// The keys in layout-macro argument order.
    public let keys: [Key]

    /// Creates a resolved layer.
    public init(id: LayerID, name: String, showsHUD: Bool, keys: [Key]) {
        self.id = id
        self.name = name
        self.showsHUD = showsHUD
        self.keys = keys
    }
}
