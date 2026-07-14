import Foundation

/// The layers shared by the Elora and Kyria firmware.
enum KeymapLayer: UInt8, CaseIterable, Equatable, Hashable, Identifiable, Sendable {
    /// The Colemak-DH base layer.
    case base = 0

    /// The toggled QWERTY gaming layer.
    case qwerty = 1

    /// The momentary navigation layer.
    case lower = 2

    /// The momentary symbols and number layer.
    case raise = 3

    /// The momentary function and RGB layer.
    case function = 4

    /// A stable identifier that matches the QMK layer number.
    var id: UInt8 { rawValue }

    /// The localized layer name shown by the app.
    var displayName: LocalizedStringResource {
        switch self {
        case .base:
            "Default"
        case .qwerty:
            "QWERTY"
        case .lower:
            "Lower"
        case .raise:
            "Raise"
        case .function:
            "Function"
        }
    }

    /// The compact unlocalized name used inside downloaded key legends.
    var legendName: String {
        switch self {
        case .base:
            "Default"
        case .qwerty:
            "QWERTY"
        case .lower:
            "Lower"
        case .raise:
            "Raise"
        case .function:
            "Fn"
        }
    }

    /// Whether dwelling on this momentary layer should present the keymap HUD.
    var isHUDLayer: Bool {
        switch self {
        case .base, .qwerty:
            false
        case .lower, .raise, .function:
            true
        }
    }

    /// Returns whether this layer is active in a QMK layer-state mask.
    /// - Parameter mask: A QMK layer-state bitmask.
    /// - Returns: `true` when this layer's bit is set.
    func isActive(in mask: UInt32) -> Bool {
        mask & (UInt32(1) << UInt32(rawValue)) != 0
    }

    /// Finds the highest active supported layer in a QMK layer-state mask.
    /// - Parameter mask: A QMK layer-state bitmask.
    /// - Returns: The highest active layer, falling back to the base layer.
    static func highestActiveLayer(in mask: UInt32) -> KeymapLayer {
        allCases.reversed().first { $0.isActive(in: mask) } ?? .base
    }
}
