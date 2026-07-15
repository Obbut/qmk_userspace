/// One encoder's counterclockwise and clockwise actions on a layer.
public struct On: Sendable {
    /// The layer selecting this mapping.
    public let layer: LayerID

    /// The counterclockwise action.
    public let counterclockwise: Key

    /// The clockwise action.
    public let clockwise: Key

    /// Creates one layer-specific encoder mapping.
    ///
    /// - Parameters:
    ///   - layer: The layer selecting this mapping.
    ///   - counterclockwise: The counterclockwise action.
    ///   - clockwise: The clockwise action.
    public init<ID: FirmwareLayerID>(
        _ layer: ID,
        counterclockwise: Key,
        clockwise: Key
    ) {
        self.layer = layer.qmkLayerID
        self.counterclockwise = counterclockwise
        self.clockwise = clockwise
    }
}
