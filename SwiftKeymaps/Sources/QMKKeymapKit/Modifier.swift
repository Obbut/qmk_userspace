/// A QMK keyboard modifier usable in chords and mod-taps.
public enum Modifier: String, CaseIterable, Sendable {
    /// The left Control key.
    case leftControl
    /// The left Shift key.
    case leftShift
    /// The left Option/Alt key.
    case leftOption
    /// The left Command/GUI key.
    case leftCommand
    /// The right Control key.
    case rightControl
    /// The right Shift key.
    case rightShift
    /// The right Option/Alt key.
    case rightOption
    /// The right Command/GUI key.
    case rightCommand

    /// The QMK wrapper macro for a modified basic keycode.
    var wrapper: String {
        switch self {
        case .leftControl: "LCTL"
        case .leftShift: "LSFT"
        case .leftOption: "LALT"
        case .leftCommand: "LGUI"
        case .rightControl: "RCTL"
        case .rightShift: "RSFT"
        case .rightOption: "RALT"
        case .rightCommand: "RGUI"
        }
    }

    /// The QMK modifier-mask constant.
    var mask: String {
        switch self {
        case .leftControl: "MOD_LCTL"
        case .leftShift: "MOD_LSFT"
        case .leftOption: "MOD_LALT"
        case .leftCommand: "MOD_LGUI"
        case .rightControl: "MOD_RCTL"
        case .rightShift: "MOD_RSFT"
        case .rightOption: "MOD_RALT"
        case .rightCommand: "MOD_RGUI"
        }
    }

    /// The basic QMK keycode constant.
    var keycode: String {
        switch self {
        case .leftControl: "KC_LCTL"
        case .leftShift: "KC_LSFT"
        case .leftOption: "KC_LALT"
        case .leftCommand: "KC_LGUI"
        case .rightControl: "KC_RCTL"
        case .rightShift: "KC_RSFT"
        case .rightOption: "KC_RALT"
        case .rightCommand: "KC_RGUI"
        }
    }

    /// The compact host-preview modifier bit.
    var previewMask: UInt16 {
        switch self {
        case .leftControl, .rightControl: 0x01
        case .leftShift, .rightShift: 0x02
        case .leftOption, .rightOption: 0x04
        case .leftCommand, .rightCommand: 0x08
        }
    }
}
