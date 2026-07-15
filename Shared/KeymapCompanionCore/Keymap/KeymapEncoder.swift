/// One physical encoder and its firmware-owned mappings across every layer.
public struct KeymapEncoder: Equatable, Sendable {
    /// The encoder's stable renderer identifier.
    public let id: String

    /// The encoder's physical board position.
    public let placement: PhysicalKeyPlacement

    /// The counterclockwise mapping across every layer.
    public let counterclockwiseKey: KeymapKey

    /// The encoder-press mapping across every layer.
    public let pressKey: KeymapKey

    /// The clockwise mapping across every layer.
    public let clockwiseKey: KeymapKey

    /// Creates an encoder definition.
    ///
    /// - Parameters:
    ///   - id: The encoder's stable renderer identifier.
    ///   - placement: The encoder's physical board position.
    ///   - counterclockwiseKey: The counterclockwise mapping across every layer.
    ///   - pressKey: The encoder-press mapping across every layer.
    ///   - clockwiseKey: The clockwise mapping across every layer.
    init(
        id: String,
        placement: PhysicalKeyPlacement,
        counterclockwiseKey: KeymapKey,
        pressKey: KeymapKey,
        clockwiseKey: KeymapKey
    ) {
        self.id = id
        self.placement = placement
        self.counterclockwiseKey = counterclockwiseKey
        self.pressKey = pressKey
        self.clockwiseKey = clockwiseKey
    }
}
