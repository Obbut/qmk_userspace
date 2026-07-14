import SwiftUI

/// The visual category assigned to a key by the keymap's RGB legend.
enum KeyStyle: Equatable, Sendable {
    /// A key without a layer-specific RGB category.
    case standard

    /// A QWERTY gaming key.
    case purple

    /// A navigation key.
    case magenta

    /// A numeric key.
    case blue

    /// A symbol key.
    case yellow

    /// A function key.
    case cyan

    /// An RGB increase or mode key.
    case green

    /// An RGB decrease key.
    case darkGreen

    /// A bootloader key.
    case red

    /// A destructive editing key.
    case orange

    /// The color used for this category in the app.
    var color: Color {
        switch self {
        case .standard:
            .accentColor
        case .purple:
            .purple
        case .magenta:
            .pink
        case .blue:
            .blue
        case .yellow:
            .yellow
        case .cyan:
            .cyan
        case .green:
            .green
        case .darkGreen:
            Color(red: 0.12, green: 0.48, blue: 0.22)
        case .red:
            .red
        case .orange:
            .orange
        }
    }
}
