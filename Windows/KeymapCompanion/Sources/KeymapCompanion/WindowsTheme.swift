import UWP
import WinUI

enum WindowsTheme {
    static func color(_ red: UInt8, _ green: UInt8, _ blue: UInt8, alpha: UInt8 = 255) -> Color {
        Color(a: alpha, r: red, g: green, b: blue)
    }

    static func brush(_ red: UInt8, _ green: UInt8, _ blue: UInt8, alpha: UInt8 = 255) -> SolidColorBrush {
        SolidColorBrush(color(red, green, blue, alpha: alpha))
    }

    static func inset(_ value: Double) -> Thickness {
        Thickness(left: value, top: value, right: value, bottom: value)
    }

    static func corners(_ value: Double) -> CornerRadius {
        CornerRadius(topLeft: value, topRight: value, bottomRight: value, bottomLeft: value)
    }

    static func card(content: UIElement, padding: Double = 20) -> Border {
        let card = Border()
        card.background = brush(35, 38, 48, alpha: 232)
        card.borderBrush = brush(255, 255, 255, alpha: 22)
        card.borderThickness = Thickness(left: 1, top: 1, right: 1, bottom: 1)
        card.cornerRadius = corners(14)
        card.padding = inset(padding)
        card.child = content
        return card
    }

    static func text(_ value: String, size: Double = 14, color: Color? = nil) -> TextBlock {
        let label = TextBlock()
        label.text = value
        label.fontSize = size
        label.foreground = SolidColorBrush(color ?? self.color(235, 238, 246))
        return label
    }
}
