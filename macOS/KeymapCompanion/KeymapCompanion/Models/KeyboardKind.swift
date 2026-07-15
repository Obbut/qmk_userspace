import KeymapCompanionCore
import Foundation

/// A keyboard model represented on the wire.
typealias KeyboardKind = KeymapCompanionCore.KeyboardKind

/// macOS-localized presentation for shared keyboard identifiers.
extension KeymapCompanionCore.KeyboardKind {
    /// The localized product name shown by the macOS app.
    var localizedDisplayName: LocalizedStringResource {
        switch self {
        case .kyria: "Kyria Rev4"
        case .elora: "Elora Rev2"
        }
    }
}
