/// A key label and its layer-specific appearance.
public struct KeyLegend: Equatable, Sendable {
    /// The compact text shown when the renderer has no native symbol.
    public let label: String

    /// The optional legend symbol for a native renderer.
    public let symbol: KeySymbol?

    /// The appearance supplied by firmware.
    public let style: ResolvedKeyStyle

    /// Creates a key legend.
    ///
    /// - Parameters:
    ///   - label: The compact fallback text.
    ///   - symbol: The optional legend symbol for a native renderer.
    ///   - style: The appearance supplied by firmware.
    init(
        label: String,
        symbol: KeySymbol? = nil,
        style: ResolvedKeyStyle = .standard
    ) {
        self.label = label
        self.symbol = symbol
        self.style = style
    }
}
