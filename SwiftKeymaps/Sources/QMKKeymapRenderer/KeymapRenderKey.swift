import QMKKeymapKit

/// A positioned physical key with a legend for every layer.
public struct KeymapRenderKey: Equatable, Identifiable, Sendable {
    /// Stable matrix-derived identity.
    public let id: String

    /// Physical size, rotation, and position.
    public let placement: PhysicalKeyPlacement

    /// Layer-major legends.
    public let legends: [KeymapRenderLegend]

    public init(id: String, placement: PhysicalKeyPlacement, legends: [KeymapRenderLegend]) {
        self.id = id
        self.placement = placement
        self.legends = legends
    }
}
