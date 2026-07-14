/// A validated keyboard-state packet received from QMK.
struct KeyboardStateReport: Equatable, Sendable {
    /// The keyboard model that sent the report.
    let keyboardKind: KeyboardKind

    /// The active nonpersistent QMK layer bitmask.
    let layerStateMask: UInt32

    /// The active persistent QMK default-layer bitmask.
    let defaultLayerStateMask: UInt32

    /// A monotonically increasing firmware packet sequence.
    let sequence: UInt32

    /// The protocol capabilities advertised by the firmware.
    let capabilities: UInt32

    /// The current persistent RGB Matrix configuration, when supported.
    let rgbSettings: RGBSettings?

    /// The union used to resolve transparent keys in the UI.
    var effectiveLayerMask: UInt32 {
        layerStateMask | defaultLayerStateMask
    }
}
