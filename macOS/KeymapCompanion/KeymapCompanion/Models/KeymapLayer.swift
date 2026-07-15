import KeymapCompanionCore
import Foundation

/// A firmware layer shared by the Elora and Kyria keymaps.
typealias KeymapLayer = KeymapCompanionCore.KeymapLayer

/// macOS-localized presentation for shared firmware layers.
extension KeymapCompanionCore.KeymapLayer {
    /// The localized layer name shown by the macOS app.
    var localizedDisplayName: LocalizedStringResource {
        switch self {
        case .base: "Default"
        case .qwerty: "QWERTY"
        case .lower: "Lower"
        case .raise: "Raise"
        case .function: "Function"
        }
    }
}
