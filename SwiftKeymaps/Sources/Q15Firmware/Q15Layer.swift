import QMKKeymapKit

/// Q15-specific layer identifiers; semantics remain owned by `ObbutKeymaps`.
enum Q15Layer {
    /// The macOS typing layer.
    static let macBase = LayerID(rawValue: 0, cIdentifier: "MAC_BASE")
    /// The Windows typing layer.
    static let windowsBase = LayerID(rawValue: 1, cIdentifier: "WIN_BASE")
    /// The macOS system layer.
    static let macFunction = LayerID(rawValue: 2, cIdentifier: "MAC_FN")
    /// The Windows system layer.
    static let windowsFunction = LayerID(rawValue: 3, cIdentifier: "WIN_FN")
    /// The common function-key layer.
    static let commonFunction = LayerID(rawValue: 4, cIdentifier: "COM_FN")
    /// The shared number and symbol layer.
    static let raise = LayerID(rawValue: 5, cIdentifier: "_RAISE")
}
