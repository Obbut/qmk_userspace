/// One physical key and its firmware-owned entries across all supported layers.
public struct KeymapKey: Equatable, Identifiable, Sendable {
    /// The stable identifier derived from the key's matrix position.
    public let id: String

    /// The firmware entries ordered by layer index.
    public let entries: [FirmwareKeymapEntry]

    /// Creates a physical key with its layer entries.
    ///
    /// - Parameters:
    ///   - id: The stable identifier derived from the key's matrix position.
    ///   - entries: The firmware entries ordered by layer index.
    public init(id: String, entries: [FirmwareKeymapEntry]) {
        self.id = id
        self.entries = entries
    }

    /// Returns the legend resolved from the highest active nontransparent layer.
    ///
    /// - Parameter activeLayerMask: The bit mask of active firmware layers.
    ///
    /// - Returns: The resolved legend, or an empty legend when the key has no entry.
    public func resolvedLegend(forActiveLayerMask activeLayerMask: UInt32) -> KeyLegend {
        for layer in KeymapLayer.allCases.reversed() where layer.isActive(inLayerMask: activeLayerMask) {
            let index = Int(layer.rawValue)
            guard index < entries.count else { continue }
            let entry = entries[index]
            if entry.keycode != 0x0001 {
                return QMKKeycodeLegend.legend(for: entry)
            }
        }
        return entries.first.map(QMKKeycodeLegend.legend(for:))
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
