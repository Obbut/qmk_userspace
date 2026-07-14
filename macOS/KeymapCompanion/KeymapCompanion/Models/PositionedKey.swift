/// A keymap key paired with its physical board position.
struct PositionedKey: Equatable, Identifiable, Sendable {
    /// The logical key and its layer mappings.
    let key: KeymapKey

    /// The switch center and rotation from the physical layout.
    let placement: PhysicalKeyPlacement

    /// Stable physical-position identity.
    var id: String {
        key.id
    }
}
