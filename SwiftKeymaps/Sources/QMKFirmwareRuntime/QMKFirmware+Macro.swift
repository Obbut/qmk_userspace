/// Marks an enum as the complete Swift implementation of one QMK firmware.
///
/// The macro adds the ``QMKFirmware`` conformance and applies the result
/// builders required by the enum's static `keymap` and `features` properties.
/// When the keymap uses inferred layer declarations, it also synthesizes the
/// firmware's nested `LayerID` enum. It emits Swift syntax only and never
/// writes generated firmware inputs.
@attached(extension, conformances: QMKFirmware)
@attached(memberAttribute)
@attached(member, names: named(LayerID))
public macro QMKFirmware() = #externalMacro(
    module: "QMKFirmwareMacros",
    type: "QMKFirmwareMacro"
)
