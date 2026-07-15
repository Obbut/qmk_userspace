/// An eight-bit red, green, and blue color shared by firmware and renderers.
public struct RGBColor: Equatable, Hashable, Sendable {
    /// The red component.
    public let red: UInt8

    /// The green component.
    public let green: UInt8

    /// The blue component.
    public let blue: UInt8

    /// Creates a color from byte-scale components.
    ///
    /// - Parameters:
    ///   - red: The red component.
    ///   - green: The green component.
    ///   - blue: The blue component.
    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// Creates a color from byte-scale components.
    ///
    /// - Parameters:
    ///   - red: The red component.
    ///   - green: The green component.
    ///   - blue: The blue component.
    /// - Returns: The composed color.
    public static func rgb(_ red: UInt8, _ green: UInt8, _ blue: UInt8) -> RGBColor {
        RGBColor(red: red, green: green, blue: blue)
    }
}
