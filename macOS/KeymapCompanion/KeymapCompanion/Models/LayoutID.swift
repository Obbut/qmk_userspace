import Foundation
import KeymapCompanionCore

/// A stable protocol-v4 keyboard layout identifier.
typealias LayoutID = KeymapCompanionCore.LayoutID

/// macOS-localized presentation for catalog layout identifiers.
extension KeymapCompanionCore.LayoutID {
    /// The product name shown by the macOS app.
    var localizedDisplayName: String { displayName }
}
