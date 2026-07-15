import QMKKeymapKit

/// Q15-specific layer identifiers; semantics remain owned by `ObbutKeymaps`.
public enum Q15Layer: UInt8, FirmwareLayerID {
    /// The macOS typing layer.
    case macBase
    /// The Windows typing layer.
    case windowsBase
    /// The macOS system layer.
    case macFunction
    /// The Windows system layer.
    case windowsFunction
    /// The common function-key layer.
    case commonFunction
    /// The shared number and symbol layer.
    case raise
}
