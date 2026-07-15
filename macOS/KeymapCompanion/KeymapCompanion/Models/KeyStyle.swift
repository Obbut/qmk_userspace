import KeymapCompanionCore
import SwiftUI

/// Catalog-resolved key presentation.
typealias KeyStyle = KeymapCompanionCore.KeyStyle

/// SwiftUI presentation for shared firmware key styles.
extension KeymapCompanionCore.KeyStyle {
    /// The color used for this category in the app.
    var color: Color {
        Color(
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255
        )
    }
}
