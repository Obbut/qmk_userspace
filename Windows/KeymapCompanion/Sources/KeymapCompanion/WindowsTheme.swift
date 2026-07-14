import UWP
import WinUI

/// Factories for the Windows app's shared visual language.
enum WindowsTheme {
    /// Creates a Windows color from byte-scale components.
    ///
    /// - Parameters:
    ///   - red: The red component.
    ///   - green: The green component.
    ///   - blue: The blue component.
    ///   - alpha: The alpha component.
    /// - Returns: The composed Windows color.
    static func makeColor(
        red: UInt8,
        green: UInt8,
        blue: UInt8,
        alpha: UInt8 = 255
    ) -> Color {
        Color(a: alpha, r: red, g: green, b: blue)
    }

    /// Creates a solid brush from byte-scale color components.
    ///
    /// - Parameters:
    ///   - red: The red component.
    ///   - green: The green component.
    ///   - blue: The blue component.
    ///   - alpha: The alpha component.
    /// - Returns: A brush containing the composed color.
    static func makeBrush(
        red: UInt8,
        green: UInt8,
        blue: UInt8,
        alpha: UInt8 = 255
    ) -> SolidColorBrush {
        SolidColorBrush(makeColor(red: red, green: green, blue: blue, alpha: alpha))
    }

    /// Creates equal edge insets.
    ///
    /// - Parameter value: The inset for every edge.
    /// - Returns: Equal edge insets.
    static func makeInsets(all value: Double) -> Thickness {
        Thickness(left: value, top: value, right: value, bottom: value)
    }

    /// Creates an equal radius for every corner.
    ///
    /// - Parameter value: The radius for every corner.
    /// - Returns: An equal-corner radius.
    static func makeCornerRadius(all value: Double) -> CornerRadius {
        CornerRadius(topLeft: value, topRight: value, bottomRight: value, bottomLeft: value)
    }

    /// Creates a standard surface card around content.
    ///
    /// - Parameters:
    ///   - content: The card's child content.
    ///   - padding: The equal content padding.
    /// - Returns: A styled surface card.
    static func makeCard(content: UIElement, padding: Double = 20) -> Border {
        let card = Border()
        card.background = makeBrush(red: 35, green: 38, blue: 48, alpha: 232)
        card.borderBrush = makeBrush(red: 255, green: 255, blue: 255, alpha: 22)
        card.borderThickness = Thickness(left: 1, top: 1, right: 1, bottom: 1)
        card.cornerRadius = makeCornerRadius(all: 14)
        card.padding = makeInsets(all: padding)
        card.child = content
        return card
    }

    /// Creates a text block with standard foreground styling.
    ///
    /// - Parameters:
    ///   - text: The text to display.
    ///   - size: The font size.
    ///   - color: An optional foreground color.
    /// - Returns: A configured text block.
    static func makeText(text: String, size: Double = 14, color: Color? = nil) -> TextBlock {
        let label = TextBlock()
        label.text = text
        label.fontSize = size
        label.foreground = SolidColorBrush(
            color ?? makeColor(red: 235, green: 238, blue: 246)
        )
        return label
    }
}
