import QMKKeymapKit

/// A physical encoder with press and rotation legends for every layer.
public struct KeymapRenderEncoder: Equatable, Identifiable, Sendable {
    /// Stable identity from the layout descriptor.
    public let id: String

    /// Physical size and position.
    public let placement: PhysicalKeyPlacement

    /// Counterclockwise legends in layer order.
    public let counterclockwiseLegends: [KeymapRenderLegend]

    /// Press legends in layer order.
    public let pressLegends: [KeymapRenderLegend]

    /// Clockwise legends in layer order.
    public let clockwiseLegends: [KeymapRenderLegend]

    public init(
        id: String,
        placement: PhysicalKeyPlacement,
        counterclockwiseLegends: [KeymapRenderLegend],
        pressLegends: [KeymapRenderLegend],
        clockwiseLegends: [KeymapRenderLegend]
    ) {
        self.id = id
        self.placement = placement
        self.counterclockwiseLegends = counterclockwiseLegends
        self.pressLegends = pressLegends
        self.clockwiseLegends = clockwiseLegends
    }
}
