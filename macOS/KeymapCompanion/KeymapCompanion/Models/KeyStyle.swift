import SwiftUI

/// The shared wire-level key style.
typealias KeyStyle = KeymapProtocol.KeyStyle

extension KeymapProtocol.KeyStyle {
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
