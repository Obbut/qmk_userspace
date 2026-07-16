/// One layer-specific key legend consumed by native renderers.
public struct KeymapRenderLegend: Equatable, Sendable {
    /// Compact fallback text.
    public let label: String

    /// Optional renderer-neutral legend symbol name.
    public let symbolName: String?

    /// Resolved key style.
    public let style: KeymapRenderStyle

    /// Whether QMK should resolve this entry through lower active layers.
    public let isTransparent: Bool

    public init(
        label: String,
        symbolName: String? = nil,
        style: KeymapRenderStyle = .standard,
        isTransparent: Bool = false
    ) {
        self.label = label
        self.symbolName = symbolName
        self.style = style
        self.isTransparent = isTransparent
    }
}
