import QMKKeymapKit

/// The sole visual vocabulary used by every Obbut keyboard.
public enum ObbutStyle: UInt16, CaseIterable, KeyStyleID {
    /// An unaccented key.
    case standard = 0
    /// A QWERTY gaming key.
    case gaming = 1
    /// A navigation key.
    case navigation = 2
    /// A numeric key.
    case number = 3
    /// A symbol key.
    case symbol = 4
    /// A function key.
    case function = 5
    /// An increasing or enabling action.
    case increase = 6
    /// A decreasing action.
    case decrease = 7
    /// A destructive editing action.
    case destructive = 8
    /// A bootloader action.
    case bootloader = 9
    /// A wireless-radio action.
    case wireless = 10
    /// A pointer button or movement action.
    case pointer = 11
    /// A neutral operating-system indicator.
    case operatingSystem = 12
}
