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

    /// Deterministic protocol-v4 style identifier, reserving zero for standard.
    public var contentID: UInt16 {
        guard self != .standard else { return 0 }
        var hash: UInt32 = 2_166_136_261
        hash = (hash ^ UInt32(color.red)) &* 16_777_619
        hash = (hash ^ UInt32(color.green)) &* 16_777_619
        hash = (hash ^ UInt32(color.blue)) &* 16_777_619
        let folded = UInt16(truncatingIfNeeded: hash ^ (hash >> 16))
        return folded == 0 ? 1 : folded
    }

    /// The unaccented appearance used when no style is supplied.
    public static let standard = KeyAppearance(color: .rgb(90, 90, 96))
}
