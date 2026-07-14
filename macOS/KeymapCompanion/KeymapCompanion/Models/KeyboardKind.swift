import Foundation

/// A Halcyon keyboard model supported by the companion protocol.
enum KeyboardKind: UInt8, CaseIterable, Equatable, Sendable {
    /// The splitkb Kyria Rev4.
    case kyria = 1

    /// The splitkb Elora Rev2.
    case elora = 2

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
