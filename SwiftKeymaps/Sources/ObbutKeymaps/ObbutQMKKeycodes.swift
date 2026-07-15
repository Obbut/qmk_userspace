import QMKKeymapKit

/// Typed QMK values whose numeric assignments are supplied by the active fork.
public extension QMKKeycode {
    static var brightnessDown: QMKKeycode { forkValue(.brightnessDown) }
    static var brightnessUp: QMKKeycode { forkValue(.brightnessUp) }
    static var missionControl: QMKKeycode { forkValue(.missionControl) }
    static var launchpad: QMKKeycode { forkValue(.launchpad) }
    static var taskView: QMKKeycode { forkValue(.taskView) }
    static var fileExplorer: QMKKeycode { forkValue(.fileExplorer) }

    static var triLayerUpper: QMKKeycode { forkValue(.triLayerUpper) }
    static var triLayerLower: QMKKeycode { forkValue(.triLayerLower) }

    static var rgbMatrixToggle: QMKKeycode { forkValue(.rgbMatrixToggle) }
    static var rgbMatrixNext: QMKKeycode { forkValue(.rgbMatrixNext) }
    static var rgbMatrixPrevious: QMKKeycode { forkValue(.rgbMatrixPrevious) }
    static var rgbMatrixHueUp: QMKKeycode { forkValue(.rgbMatrixHueUp) }
    static var rgbMatrixHueDown: QMKKeycode { forkValue(.rgbMatrixHueDown) }
    static var rgbMatrixSaturationUp: QMKKeycode { forkValue(.rgbMatrixSaturationUp) }
    static var rgbMatrixSaturationDown: QMKKeycode { forkValue(.rgbMatrixSaturationDown) }
    static var rgbMatrixValueUp: QMKKeycode { forkValue(.rgbMatrixValueUp) }
    static var rgbMatrixValueDown: QMKKeycode { forkValue(.rgbMatrixValueDown) }

    /// Keychron's pre-RGB-Matrix keycode range used by the Q15 fork.
    static var keychronRGBToggle: QMKKeycode { forkValue(.keychronRGBToggle) }
    static var keychronRGBValueUp: QMKKeycode { forkValue(.keychronRGBValueUp) }
    static var keychronRGBValueDown: QMKKeycode { forkValue(.keychronRGBValueDown) }
    static var keychronRGBSpeedUp: QMKKeycode { forkValue(.keychronRGBSpeedUp) }
    static var keychronRGBSpeedDown: QMKKeycode { forkValue(.keychronRGBSpeedDown) }

    static var pointerButton1: QMKKeycode { forkValue(.pointerButton1) }
    static var pointerButton2: QMKKeycode { forkValue(.pointerButton2) }
    static var pointerButton3: QMKKeycode { forkValue(.pointerButton3) }
    static var browserBack: QMKKeycode { forkValue(.browserBack) }
    static var browserForward: QMKKeycode { forkValue(.browserForward) }
    static var pointerScroll: QMKKeycode { forkValue(.pointerScroll) }
    static var pointerSniper: QMKKeycode { forkValue(.pointerSniper) }
    static var pointerDragLock: QMKKeycode { forkValue(.pointerDragLock) }
    static var pointerSensitivityDown: QMKKeycode { forkValue(.pointerSensitivityDown) }
    static var pointerSensitivityUp: QMKKeycode { forkValue(.pointerSensitivityUp) }
    static var pointerScrollSpeedDown: QMKKeycode { forkValue(.pointerScrollSpeedDown) }
    static var pointerScrollSpeedUp: QMKKeycode { forkValue(.pointerScrollSpeedUp) }

    static var keychronBluetoothHost1: QMKKeycode { forkValue(.keychronBluetoothHost1) }
    static var keychronBluetoothHost2: QMKKeycode { forkValue(.keychronBluetoothHost2) }
    static var keychronBluetoothHost3: QMKKeycode { forkValue(.keychronBluetoothHost3) }
    static var keychronWireless24GHz: QMKKeycode { forkValue(.keychronWireless24GHz) }
    static var keychronBatteryLevel: QMKKeycode { forkValue(.keychronBatteryLevel) }
}

fileprivate enum ForkKeycode {
    case brightnessDown
    case brightnessUp
    case missionControl
    case launchpad
    case taskView
    case fileExplorer
    case triLayerUpper
    case triLayerLower
    case rgbMatrixToggle
    case rgbMatrixNext
    case rgbMatrixPrevious
    case rgbMatrixHueUp
    case rgbMatrixHueDown
    case rgbMatrixSaturationUp
    case rgbMatrixSaturationDown
    case rgbMatrixValueUp
    case rgbMatrixValueDown
    case keychronRGBToggle
    case keychronRGBValueUp
    case keychronRGBValueDown
    case keychronRGBSpeedUp
    case keychronRGBSpeedDown
    case pointerButton1
    case pointerButton2
    case pointerButton3
    case browserBack
    case browserForward
    case pointerScroll
    case pointerSniper
    case pointerDragLock
    case pointerSensitivityDown
    case pointerSensitivityUp
    case pointerScrollSpeedDown
    case pointerScrollSpeedUp
    case keychronBluetoothHost1
    case keychronBluetoothHost2
    case keychronBluetoothHost3
    case keychronWireless24GHz
    case keychronBatteryLevel
}

fileprivate func forkValue(_ keycode: ForkKeycode) -> QMKKeycode {
#if hasFeature(Embedded)
    let value: UInt16 = switch keycode {
    case .brightnessDown: obbut_qmk_keycode_brightness_down()
    case .brightnessUp: obbut_qmk_keycode_brightness_up()
    case .missionControl: obbut_qmk_keycode_mission_control()
    case .launchpad: obbut_qmk_keycode_launchpad()
    case .taskView: obbut_qmk_keycode_task_view()
    case .fileExplorer: obbut_qmk_keycode_file_explorer()
    case .triLayerUpper: obbut_qmk_keycode_tri_layer_upper()
    case .triLayerLower: obbut_qmk_keycode_tri_layer_lower()
    case .rgbMatrixToggle: obbut_qmk_keycode_rgb_matrix_toggle()
    case .rgbMatrixNext: obbut_qmk_keycode_rgb_matrix_next()
    case .rgbMatrixPrevious: obbut_qmk_keycode_rgb_matrix_previous()
    case .rgbMatrixHueUp: obbut_qmk_keycode_rgb_matrix_hue_up()
    case .rgbMatrixHueDown: obbut_qmk_keycode_rgb_matrix_hue_down()
    case .rgbMatrixSaturationUp: obbut_qmk_keycode_rgb_matrix_saturation_up()
    case .rgbMatrixSaturationDown: obbut_qmk_keycode_rgb_matrix_saturation_down()
    case .rgbMatrixValueUp: obbut_qmk_keycode_rgb_matrix_value_up()
    case .rgbMatrixValueDown: obbut_qmk_keycode_rgb_matrix_value_down()
    case .keychronRGBToggle: obbut_qmk_keycode_rgb_matrix_toggle()
    case .keychronRGBValueUp: obbut_qmk_keycode_rgb_matrix_value_up()
    case .keychronRGBValueDown: obbut_qmk_keycode_rgb_matrix_value_down()
    case .keychronRGBSpeedUp: obbut_qmk_keycode_rgb_matrix_speed_up()
    case .keychronRGBSpeedDown: obbut_qmk_keycode_rgb_matrix_speed_down()
    case .pointerButton1: obbut_qmk_keycode_pointer_button_1()
    case .pointerButton2: obbut_qmk_keycode_pointer_button_2()
    case .pointerButton3: obbut_qmk_keycode_pointer_button_3()
    case .browserBack: obbut_qmk_keycode_browser_back()
    case .browserForward: obbut_qmk_keycode_browser_forward()
    case .pointerScroll: obbut_qmk_keycode_pointer_scroll()
    case .pointerSniper: obbut_qmk_keycode_pointer_sniper()
    case .pointerDragLock: obbut_qmk_keycode_pointer_drag_lock()
    case .pointerSensitivityDown: obbut_qmk_keycode_pointer_sensitivity_down()
    case .pointerSensitivityUp: obbut_qmk_keycode_pointer_sensitivity_up()
    case .pointerScrollSpeedDown: obbut_qmk_keycode_pointer_scroll_speed_down()
    case .pointerScrollSpeedUp: obbut_qmk_keycode_pointer_scroll_speed_up()
    case .keychronBluetoothHost1: obbut_qmk_keycode_keychron_bluetooth_host_1()
    case .keychronBluetoothHost2: obbut_qmk_keycode_keychron_bluetooth_host_2()
    case .keychronBluetoothHost3: obbut_qmk_keycode_keychron_bluetooth_host_3()
    case .keychronWireless24GHz: obbut_qmk_keycode_keychron_wireless_24_ghz()
    case .keychronBatteryLevel: obbut_qmk_keycode_keychron_battery_level()
    }
    return QMKKeycode(rawValue: value)
#else
    let value: UInt16 = switch keycode {
    case .brightnessDown: 0x00BE
    case .brightnessUp: 0x00BD
    case .missionControl: 0x7E04
    case .launchpad: 0x00C2
    case .taskView: 0x7E06
    case .fileExplorer: 0x7E07
    case .triLayerUpper: 0x7C78
    case .triLayerLower: 0x7C77
    case .rgbMatrixToggle: 0x7842
    case .rgbMatrixNext: 0x7843
    case .rgbMatrixPrevious: 0x7844
    case .rgbMatrixHueUp: 0x7845
    case .rgbMatrixHueDown: 0x7846
    case .rgbMatrixSaturationUp: 0x7847
    case .rgbMatrixSaturationDown: 0x7848
    case .rgbMatrixValueUp: 0x7849
    case .rgbMatrixValueDown: 0x784A
    case .keychronRGBToggle: 0x7820
    case .keychronRGBValueUp: 0x7827
    case .keychronRGBValueDown: 0x7828
    case .keychronRGBSpeedUp: 0x7829
    case .keychronRGBSpeedDown: 0x782A
    case .pointerButton1: 0x00D1
    case .pointerButton2: 0x00D2
    case .pointerButton3: 0x00D3
    case .browserBack: 0x00B6
    case .browserForward: 0x00B7
    case .pointerScroll: 0x7E40
    case .pointerSniper: 0x7E41
    case .pointerDragLock: 0x7E42
    case .pointerSensitivityDown: 0x7E43
    case .pointerSensitivityUp: 0x7E44
    case .pointerScrollSpeedDown: 0x7E45
    case .pointerScrollSpeedUp: 0x7E46
    case .keychronBluetoothHost1: 0x7E0B
    case .keychronBluetoothHost2: 0x7E0C
    case .keychronBluetoothHost3: 0x7E0D
    case .keychronWireless24GHz: 0x7E0E
    case .keychronBatteryLevel: 0x7E0F
    }
    return QMKKeycode(rawValue: value)
#endif
}
