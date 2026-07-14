/// A key label and its layer-specific RGB category.
struct KeyLegend: Equatable, Sendable {
    /// The compact technical label displayed on the key cap.
    let label: String

    /// The visual category for the key.
    let style: KeyStyle

    /// Creates a key legend.
    /// - Parameters:
    ///   - label: The compact technical key label.
    ///   - style: The RGB-inspired visual category.
    init(label: String, style: KeyStyle = .standard) {
        self.label = label
        self.style = style
    }
}
