/// One physical key and its firmware-owned entries across all supported layers.
public struct KeymapKey: Equatable, Identifiable, Sendable {
    /// The stable identifier derived from the key's matrix position.
    public let id: String

    /// The firmware entries ordered by layer index.
    public let entries: [FirmwareKeymapEntry]

    /// The catalog-resolved legends ordered by layer index.
    public let legends: [KeyLegend]

    /// Creates a physical key with its layer entries.
    ///
    /// - Parameters:
    ///   - id: The stable identifier derived from the key's matrix position.
    ///   - entries: The firmware entries ordered by layer index.
    ///   - legends: The catalog-resolved legends ordered by layer index.
    public init(id: String, entries: [FirmwareKeymapEntry], legends: [KeyLegend]) {
        precondition(entries.count == legends.count, "Every keymap entry needs a resolved legend.")
        self.id = id
        self.entries = entries
        self.legends = legends
    }

    /// Returns the legend resolved from the highest active nontransparent layer.
    ///
    /// - Parameter activeLayerMask: The bit mask of active firmware layers.
    ///
    /// - Returns: The resolved legend, or an empty legend when the key has no entry.
    public func resolvedLegend(forActiveLayerMask activeLayerMask: UInt32) -> KeyLegend {
        for index in entries.indices.reversed()
        where activeLayerMask & (UInt32(1) << UInt32(index)) != 0 {
            let entry = entries[index]
            if entry.keycode != 0x0001 {
                return legends[index]
            }
        }
        return legends.first
            ?? KeyLegend(label: "")
    }

    /// Returns whether the key has a nontransparent mapping on a layer.
    ///
    /// - Parameter layer: The layer to inspect.
    ///
    /// - Returns: `true` when the layer contains a direct mapping.
    public func isDirectlyMapped(on layer: KeymapLayer) -> Bool {
        let index = Int(layer.rawValue)
        return index < entries.count && entries[index].keycode != 0x0001
    }
}
