import QMKKeymapKit

/// A domain-erased layer used by generated artifacts and host previews.
public struct AnyFirmwareLayer: Sendable {
    /// The stable layer identifier.
    public let id: LayerID

    /// The user-facing layer name.
    public let name: String

    /// Whether this layer is eligible for the transient HUD.
    public let showsHUD: Bool

    /// The keys in QMK layout-macro order.
    public let keys: [AnyFirmwareKey]

    /// Erases a domain-typed layer.
    ///
    /// - Parameter layer: The layer to erase.
    public init<Domain: KeymapDomain>(_ layer: Layer<Domain>) {
        id = layer.id
        name = layer.name
        showsHUD = layer.showsHUD
        keys = layer.keys.map(AnyFirmwareKey.init)
    }
}
