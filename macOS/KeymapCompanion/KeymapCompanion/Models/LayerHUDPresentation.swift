/// The current layer and effective keymap state rendered while the HUD is visible.
struct LayerHUDPresentation: Equatable, Sendable {
    /// The current layer highlighted by the HUD.
    let layer: KeymapLayer

    /// The complete layer stack used to resolve transparent mappings.
    let activeLayerMask: UInt32
}
