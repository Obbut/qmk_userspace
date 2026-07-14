import Foundation

/// The shared wire-level keyboard identifier.
typealias KeyboardKind = KeymapProtocol.KeyboardKind

extension KeymapProtocol.KeyboardKind {
    /// The localized product name shown by the app.
    var displayName: LocalizedStringResource {
        switch self {
        case .kyria:
            "Kyria Rev4"
        case .elora:
            "Elora Rev2"
        }
    }
}
