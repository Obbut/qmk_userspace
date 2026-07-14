/// A keymap key paired with its physical board position.
public struct PositionedKey: Equatable, Identifiable, Sendable {
    /// The firmware-owned key definition.
    public let key: KeymapKey

    /// The key's physical board position.
    public let placement: PhysicalKeyPlacement

    /// The stable identifier inherited from ``key``.
    public var id: String { key.id }

    /// Creates a positioned key.
    ///
    /// - Parameters:
    ///   - key: The firmware-owned key definition.
    ///   - placement: The key's physical board position.
    init(key: KeymapKey, placement: PhysicalKeyPlacement) {
        self.key = key
        self.placement = placement
    }
}
