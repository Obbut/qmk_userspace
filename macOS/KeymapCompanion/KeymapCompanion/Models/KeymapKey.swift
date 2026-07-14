/// One physical key and its firmware-owned entries across all supported layers.
struct KeymapKey: Equatable, Identifiable, Sendable {
    /// Stable physical-position identity.
    let id: String

    /// Entries ordered by `KeymapLayer.rawValue`.
    let entries: [FirmwareKeymapEntry]

    /// Resolves the label QMK produces for a complete active-layer mask.
    /// - Parameter activeLayerMask: The union of QMK's layer and default-layer masks.
    /// - Returns: The effective legend after transparent layers fall through.
    func resolvedLegend(activeLayerMask: UInt32) -> KeyLegend {
        for layer in KeymapLayer.allCases.reversed() where layer.isActive(in: activeLayerMask) {
            let entry = entries[Int(layer.rawValue)]
            if entry.keycode != 0x0001 {
                return QMKKeycodeLegend.legend(for: entry)
            }
        }
        return QMKKeycodeLegend.legend(for: entries[0])
    }

    /// Returns whether the displayed layer directly maps this key.
    /// - Parameter layer: The highest visible layer.
    /// - Returns: `true` for a direct mapping and `false` for a transparent key.
    func isDirectlyMapped(on layer: KeymapLayer) -> Bool {
        entries[Int(layer.rawValue)].keycode != 0x0001
    }
}
