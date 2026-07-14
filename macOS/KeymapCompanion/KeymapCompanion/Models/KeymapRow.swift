/// A visual row containing the keys on both halves of a split keyboard.
struct KeymapRow: Equatable, Identifiable, Sendable {
    /// Stable row identity.
    let id: String

    /// Keys on the left half, ordered from outside to inside.
    let leftKeys: [KeymapKey]

    /// Keys on the right half, ordered from inside to outside.
    let rightKeys: [KeymapKey]

    /// Whether the shorter row should align toward the inner thumb clusters.
    let isThumbRow: Bool
}
