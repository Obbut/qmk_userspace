import QMKKeymapKit

/// Layer identifiers shared by Halcyon and Planck firmware.
public enum ObbutLayer {
    /// The Colemak-DH typing layer.
    public static let base = LayerID(rawValue: 0, cIdentifier: "_DEFAULT")
    /// The QWERTY gaming layer.
    public static let qwerty = LayerID(rawValue: 1, cIdentifier: "_QWERTY")
    /// The navigation layer.
    public static let lower = LayerID(rawValue: 2, cIdentifier: "_LOWER")
    /// The number and symbol layer.
    public static let raise = LayerID(rawValue: 3, cIdentifier: "_RAISE")
    /// The function and firmware-control layer.
    public static let function = LayerID(rawValue: 4, cIdentifier: "_FUNCTION")
    /// The Kyria automatic pointer layer.
    public static let pointer = LayerID(rawValue: 5, cIdentifier: "_POINTER")
}
