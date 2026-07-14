/// One matrix entry downloaded from the keyboard firmware.
struct FirmwareKeymapEntry: Equatable, Sendable {
    /// The compiled 16-bit QMK keycode.
    let keycode: UInt16

    /// A firmware-defined override for semantics that disappear during C preprocessing.
    let semantic: UInt8

    /// The firmware-defined RGB-inspired presentation category.
    let style: KeyStyle
}
