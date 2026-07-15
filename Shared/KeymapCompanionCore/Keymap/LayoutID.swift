import Foundation
import ObbutKeyboardCatalog

/// An opaque, stable protocol-v4 keyboard layout identifier.
public struct LayoutID: Equatable, Hashable, RawRepresentable, Sendable {
    /// The 32-bit wire value generated from the layout's stable string identifier.
    public let rawValue: UInt32

    /// Creates a layout identifier from its protocol representation.
    ///
    /// - Parameter rawValue: The 32-bit wire value.
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    /// The catalog display name, or a diagnostic fallback for an unknown layout.
    public var displayName: String {
        ObbutKeyboardCatalog.firmware(layoutID: rawValue)?.layout.displayName
            ?? String(format: "Unknown layout 0x%08X", rawValue)
    }

    /// The Kyria layout identifier from the compiled Obbut catalog.
    public static let kyria = known(named: "kyria")

    /// The Elora layout identifier from the compiled Obbut catalog.
    public static let elora = known(named: "elora")

    /// The Q15 layout identifier from the compiled Obbut catalog.
    public static let q15 = known(named: "q15")

    /// The Planck layout identifier from the compiled Obbut catalog.
    public static let planck = known(named: "planck")

    /// Resolves a required layout from the build-time catalog.
    private static func known(named name: String) -> LayoutID {
        guard let firmware = ObbutKeyboardCatalog.firmware(named: name) else {
            preconditionFailure("The Obbut keyboard catalog must include \(name).")
        }
        return LayoutID(rawValue: firmware.layoutID)
    }
}
