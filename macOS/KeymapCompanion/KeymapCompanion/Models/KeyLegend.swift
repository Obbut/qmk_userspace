/// A key label and its layer-specific RGB category.
struct KeyLegend: Equatable, Sendable {
    /// The readable key name used for text legends and accessibility.
    let label: String

    /// The native Apple glyph used instead of text when available.
    let systemImageName: String?

    /// The visual category for the key.
    let style: KeyStyle

    /// Creates a key legend.
    /// - Parameters:
    ///   - label: The readable key name.
    ///   - systemImageName: An optional SF Symbol representing the key.
    ///   - style: The RGB-inspired visual category.
    init(
        label: String,
        systemImageName: String? = nil,
        style: KeyStyle = .standard
    ) {
        self.label = label
        self.systemImageName = systemImageName
        self.style = style
    }
}
