/// One physical key and its mappings across all supported layers.
struct KeymapKey: Equatable, Identifiable, Sendable {
    /// Stable physical-position identity.
    let id: String

    /// The label used when no higher active layer overrides the key.
    let baseLegend: KeyLegend

    /// Layer-specific mappings; a missing entry represents QMK transparency.
    let overrides: [KeymapLayer: KeyLegend]

    /// Resolves the label QMK produces for a complete active-layer mask.
    /// - Parameter activeLayerMask: The union of QMK's layer and default-layer masks.
    /// - Returns: The effective legend after transparent layers fall through.
    func resolvedLegend(activeLayerMask: UInt32) -> KeyLegend {
        for layer in KeymapLayer.allCases.reversed() where layer.isActive(in: activeLayerMask) {
            if layer == .base {
                return baseLegend
            }
            if let legend = overrides[layer] {
                return legend
            }
        }
        return baseLegend
    }

    /// Returns whether the displayed layer directly maps this key.
    /// - Parameter layer: The highest visible layer.
    /// - Returns: `true` for a direct mapping and `false` for a transparent key.
    func isDirectlyMapped(on layer: KeymapLayer) -> Bool {
        layer == .base || overrides[layer] != nil
    }
}
