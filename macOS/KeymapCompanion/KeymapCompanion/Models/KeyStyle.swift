import KeymapCompanionCore
import SwiftUI

/// SwiftUI presentation for shared firmware key styles.
extension KeymapCompanionCore.ResolvedKeyStyle {
    /// The color used for this style in the app.
    var color: Color {
        Color(
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255
        )
    }
}
