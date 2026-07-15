/// A QMK keyboard modifier usable in chords and mod-taps.
public enum Modifier: Sendable {
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

    /// The basic QMK keycode value.
    var keycode: UInt16 {
        switch self {
        case .leftControl: 0x00E0
        case .leftShift: 0x00E1
        case .leftOption: 0x00E2
        case .leftCommand: 0x00E3
        case .rightControl: 0x00E4
        case .rightShift: 0x00E5
        case .rightOption: 0x00E6
        case .rightCommand: 0x00E7
        }
    }

    /// QMK's compact modifier field, including its right-hand flag.
    var qmkMask: UInt16 {
        switch self {
        case .leftControl: 0x01
        case .leftShift: 0x02
        case .leftOption: 0x04
        case .leftCommand: 0x08
        case .rightControl: 0x11
        case .rightShift: 0x12
        case .rightOption: 0x14
        case .rightCommand: 0x18
        }
    }
}
