#if hasFeature(Embedded)
import QMKFirmwareRuntime

#if OBBUT_FIRMWARE_KYRIA
import KyriaFirmware
typealias SelectedFirmwareRuntime = FirmwareRuntime<KyriaFirmware>
#elseif OBBUT_FIRMWARE_ELORA
import EloraFirmware
typealias SelectedFirmwareRuntime = FirmwareRuntime<EloraFirmware>
#elseif OBBUT_FIRMWARE_Q15
import Q15Firmware
typealias SelectedFirmwareRuntime = FirmwareRuntime<Q15Firmware>
#elseif OBBUT_FIRMWARE_PLANCK
import PlanckFirmware
typealias SelectedFirmwareRuntime = FirmwareRuntime<PlanckFirmware>
#else
#error("Select exactly one OBBUT_FIRMWARE_* definition.")
#endif

nonisolated(unsafe) fileprivate var selectedFirmwareRuntime = SelectedFirmwareRuntime()

@c @implementation
func qmk_swift_post_init() {
    selectedFirmwareRuntime.postInitialize()
}

@c @implementation
func qmk_swift_housekeeping() {
    selectedFirmwareRuntime.housekeeping()
}

@c @implementation
func qmk_swift_process_record(_ keycode: UInt16, _ pressed: UInt8) -> UInt8 {
    selectedFirmwareRuntime.processRecord(keycode: keycode, isPressed: pressed != 0) ? 1 : 0
}

@c @implementation
func qmk_swift_layer_state_set(_ state: UInt32) -> UInt32 {
    selectedFirmwareRuntime.layerStateSet(state)
}

@c @implementation
func qmk_swift_pointing_device_init() {
    selectedFirmwareRuntime.pointingDeviceInitialize()
}

@c @implementation
func qmk_swift_pointing_device_task(
    _ x: UnsafeMutablePointer<Int8>?,
    _ y: UnsafeMutablePointer<Int8>?,
    _ horizontal: UnsafeMutablePointer<Int8>?,
    _ vertical: UnsafeMutablePointer<Int8>?,
    _ buttons: UnsafeMutablePointer<UInt8>?
) {
    guard let x, let y, let horizontal, let vertical, let buttons else {
        return
    }
    var report = PointerReport(
        x: x.pointee,
        y: y.pointee,
        horizontal: horizontal.pointee,
        vertical: vertical.pointee,
        buttons: buttons.pointee
    )
    selectedFirmwareRuntime.pointingDeviceTask(&report)
    x.pointee = report.x
    y.pointee = report.y
    horizontal.pointee = report.horizontal
    vertical.pointee = report.vertical
    buttons.pointee = report.buttons
}

@c @implementation
func qmk_swift_rgb_matrix_indicators(_ lowerBound: UInt8, _ upperBound: UInt8) -> UInt8 {
    selectedFirmwareRuntime.rgbMatrixIndicators(
        lowerBound: lowerBound,
        upperBound: upperBound
    ) ? 1 : 0
}

@c @implementation
func qmk_swift_raw_hid_receive(
    _ data: UnsafeMutablePointer<UInt8>?,
    _ length: UInt8
) -> UInt8 {
    guard let data else {
        return 0
    }
    return selectedFirmwareRuntime.rawHIDReceive(data, length: length) ? 1 : 0
}

@c @implementation
func qmk_swift_receive_split_state(_ rgbPreviewMode: UInt8, _ pointerDragLockActive: UInt8) {
    selectedFirmwareRuntime.receiveSplitState(
        rgbPreviewMode: rgbPreviewMode != 0,
        pointerDragLockActive: pointerDragLockActive != 0
    )
}

@c @implementation
func qmk_swift_rgb_settings_applied() {
    selectedFirmwareRuntime.rgbSettingsApplied()
}

@c @implementation
func qmk_swift_keycode_at(_ layer: UInt8, _ row: UInt8, _ column: UInt8) -> UInt16 {
    selectedFirmwareRuntime.keycode(layer: layer, row: row, column: column)
}

@c @implementation
func qmk_swift_legend_id_at(_ layer: UInt8, _ row: UInt8, _ column: UInt8) -> UInt16 {
    selectedFirmwareRuntime.legendID(layer: layer, row: row, column: column)
}

@c @implementation
func qmk_swift_style_id_at(_ layer: UInt8, _ row: UInt8, _ column: UInt8) -> UInt16 {
    selectedFirmwareRuntime.styleID(layer: layer, row: row, column: column)
}

@c @implementation
func qmk_swift_style_color_at(_ layer: UInt8, _ row: UInt8, _ column: UInt8) -> UInt32 {
    selectedFirmwareRuntime.packedStyleColor(layer: layer, row: row, column: column)
}

@c @implementation
func qmk_swift_encoder_keycode_at(
    _ layer: UInt8,
    _ encoder: UInt8,
    _ direction: UInt8
) -> UInt16 {
    selectedFirmwareRuntime.encoderKeycode(
        layer: layer,
        encoder: encoder,
        direction: direction
    )
}

@c @implementation
func qmk_swift_encoder_legend_id_at(
    _ layer: UInt8,
    _ encoder: UInt8,
    _ direction: UInt8
) -> UInt16 {
    selectedFirmwareRuntime.encoderLegendID(
        layer: layer,
        encoder: encoder,
        direction: direction
    )
}

@c @implementation
func qmk_swift_encoder_style_id_at(
    _ layer: UInt8,
    _ encoder: UInt8,
    _ direction: UInt8
) -> UInt16 {
    selectedFirmwareRuntime.encoderStyleID(
        layer: layer,
        encoder: encoder,
        direction: direction
    )
}

@c @implementation
func qmk_swift_layer_count() -> UInt8 {
    selectedFirmwareRuntime.layerCount
}

@c @implementation
func qmk_swift_encoder_count() -> UInt8 {
    selectedFirmwareRuntime.encoderCount
}

@c @implementation
func qmk_swift_layout_id() -> UInt32 {
    selectedFirmwareRuntime.layoutID
}

@c @implementation
func qmk_swift_legend_fingerprint() -> UInt32 {
    selectedFirmwareRuntime.legendFingerprint
}

@c @implementation
func qmk_swift_style_fingerprint() -> UInt32 {
    selectedFirmwareRuntime.styleFingerprint
}
#endif
