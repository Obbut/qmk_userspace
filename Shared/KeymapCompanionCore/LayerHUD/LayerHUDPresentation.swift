/// The layer and effective keymap state rendered by a transient HUD.
public struct LayerHUDPresentation: Equatable, Sendable {
    /// The highest active layer.
    public let layer: KeymapLayer

    /// The bit mask of all active and default firmware layers.
    public let activeLayerMask: UInt32

    /// Creates a layer HUD snapshot.
    ///
    /// - Parameters:
    ///   - layer: The highest active layer.
    ///   - activeLayerMask: The bit mask of all active and default firmware layers.
    public init(layer: KeymapLayer, activeLayerMask: UInt32) {
        self.layer = layer
        self.activeLayerMask = activeLayerMask
    }
}
