#if canImport(SwiftUI)
import QMKFirmwareRuntime

/// Creates the keymap view embedded in an Xcode `#Preview` declaration.
///
/// The view defaults to an all-layers overview and includes an interactive
/// selector for inspecting one authored layer at a time.
///
/// - Parameter firmware: The concrete authored firmware type to render.
/// - Returns: The production renderer configured for the firmware definition.
@freestanding(expression)
public macro KeymapPreview<Firmware: QMKFirmware>(
    _ firmware: Firmware.Type
) -> KeymapPreviewView<Firmware> = #externalMacro(
    module: "QMKKeymapMacrosPlugin",
    type: "KeymapPreviewMacro"
)
#endif
