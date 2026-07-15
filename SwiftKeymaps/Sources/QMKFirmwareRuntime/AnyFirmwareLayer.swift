import QMKKeymapKit

/// A resolved layer used by generated artifacts and host previews.
public struct AnyFirmwareLayer: Sendable {
    /// The stable layer identifier.
    public let id: LayerID

    /// The user-facing layer name.
    public let name: String

    /// Whether this layer is eligible for the transient HUD.
    public let showsHUD: Bool

    /// The keys in QMK layout-macro order.
    public let keys: [AnyFirmwareKey]

    /// Resolves one layer against automatically collected metadata.
    ///
    /// - Parameters:
    ///   - layer: The source layer to resolve.
    ///   - metadata: The metadata collected from the complete firmware.
    init(_ layer: Layer, metadata: GeneratedKeyMetadata) {
        id = layer.id
        name = layer.name
        showsHUD = layer.showsHUD
        keys = layer.keys.map { AnyFirmwareKey($0, metadata: metadata) }
    }
}
