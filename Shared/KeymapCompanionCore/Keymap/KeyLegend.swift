/// A key label and its layer-specific presentation category.
public struct KeyLegend: Equatable, Sendable {
    /// The compact text shown when the renderer has no native symbol.
    public let label: String

    /// The optional semantic symbol for a native renderer.
    public let symbol: KeySymbol?

    /// The presentation category supplied by firmware.
    public let style: KeyStyle

    /// Creates a key legend.
    ///
    /// - Parameters:
    ///   - label: The compact fallback text.
    ///   - symbol: The optional semantic symbol for a native renderer.
    ///   - style: The presentation category supplied by firmware.
    init(
        label: String,
        symbol: KeySymbol? = nil,
        style: KeyStyle = .standard
    ) {
        self.label = label
        self.symbol = symbol
        self.style = style
    }
}
