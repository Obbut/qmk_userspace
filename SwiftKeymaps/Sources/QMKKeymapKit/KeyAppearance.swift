/// Portable presentation produced by a key style.
public struct KeyAppearance: Equatable, Hashable, Sendable {
    /// The color shared by previews, companions, and firmware lighting.
    public let color: RGBColor

    /// Creates a portable key appearance.
    ///
    /// - Parameter color: The color shared by every renderer.
    public init(color: RGBColor) {
        self.color = color
    }

    /// The unaccented appearance used when no style is supplied.
    public static let standard = KeyAppearance(color: .rgb(90, 90, 96))
}
