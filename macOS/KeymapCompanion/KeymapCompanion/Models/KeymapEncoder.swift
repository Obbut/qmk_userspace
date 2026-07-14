/// One physical encoder and its firmware-owned mappings across every layer.
struct KeymapEncoder: Equatable, Sendable {
    /// The encoder's stable physical identity.
    let id: String

    /// The encoder's center in the shared board coordinate space.
    let placement: PhysicalKeyPlacement

    /// The counter-clockwise action across every layer.
    let counterClockwiseKey: KeymapKey

    /// The matrix-backed push action across every layer.
    let pressKey: KeymapKey

    /// The clockwise action across every layer.
    let clockwiseKey: KeymapKey
}
