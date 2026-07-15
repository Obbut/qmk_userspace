import QMKKeymapKit

/// Layer identifiers shared by Halcyon firmware.
public enum ObbutLayer: UInt8, FirmwareLayerID {
    /// The Colemak-DH typing layer.
    case base
    /// The QWERTY gaming layer.
    case qwerty
    /// The navigation layer.
    case lower
    /// The number and symbol layer.
    case raise
    /// The function and firmware-control layer.
    case function
    /// The Kyria automatic pointer layer.
    case pointer
}
