/// A QMK callback that can be implemented by a selected Embedded Swift module.
public enum EmbeddedSwiftCallback: String, CaseIterable, Sendable {
    /// Runs after QMK initializes the keyboard.
    case keyboardPostInit

    /// Runs from QMK's periodic housekeeping task.
    case housekeeping

    /// Filters or handles one key event.
    case processRecord

    /// Transforms the active QMK layer-state bit field.
    case layerStateSet

    /// Initializes a pointing device.
    case pointingDeviceInit

    /// Transforms one pointing-device report in place.
    case pointingDeviceTask

    /// Adds advanced RGB Matrix indicators.
    case rgbMatrixIndicatorsAdvanced

    /// Receives one Raw HID packet.
    case rawHIDReceive
}
