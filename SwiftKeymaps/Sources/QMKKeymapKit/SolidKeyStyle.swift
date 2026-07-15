/// A key style that applies one color on every platform.
public struct SolidKeyStyle: KeyStyle, Equatable, Hashable, Sendable {
    /// The shared renderer and firmware color.
    public let color: RGBColor

    /// Creates a solid-color key style.
    ///
    /// - Parameter color: The color used by renderers and firmware lighting.
    public init(color: RGBColor) {
        self.color = color
    }

    /// Resolves the configured solid color.
    public func makeAppearance(configuration: KeyStyleConfiguration) -> KeyAppearance {
        KeyAppearance(color: color)
    }
}

public extension KeyStyle where Self == SolidKeyStyle {
    /// The standard unaccented key color.
    static var standard: SolidKeyStyle { SolidKeyStyle(color: .rgb(90, 90, 96)) }

    /// A red key style.
    static var red: SolidKeyStyle { SolidKeyStyle(color: .rgb(255, 0, 0)) }

    /// A green key style.
    static var green: SolidKeyStyle { SolidKeyStyle(color: .rgb(0, 255, 0)) }

    /// A blue key style.
    static var blue: SolidKeyStyle { SolidKeyStyle(color: .rgb(0, 0, 255)) }

    /// A yellow key style.
    static var yellow: SolidKeyStyle { SolidKeyStyle(color: .rgb(255, 255, 0)) }

    /// A magenta key style.
    static var magenta: SolidKeyStyle { SolidKeyStyle(color: .rgb(255, 0, 255)) }

    /// A cyan key style.
    static var cyan: SolidKeyStyle { SolidKeyStyle(color: .rgb(0, 255, 255)) }

    /// An orange key style.
    static var orange: SolidKeyStyle { SolidKeyStyle(color: .rgb(255, 128, 0)) }

    /// A white key style.
    static var white: SolidKeyStyle { SolidKeyStyle(color: .rgb(255, 255, 255)) }

    /// Creates a solid style from byte-scale RGB components.
    static func rgb(_ red: UInt8, _ green: UInt8, _ blue: UInt8) -> SolidKeyStyle {
        SolidKeyStyle(color: .rgb(red, green, blue))
    }
}
