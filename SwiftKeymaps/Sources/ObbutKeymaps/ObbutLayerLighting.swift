import QMKFirmwareRuntime
import QMKKeymapKit

/// Style-driven RGB layer lighting shared by Obbut keyboards.
public struct ObbutLayerLighting: FirmwareFeature, Sendable {
    public typealias State = EmptyFeatureState
    public static let initialState = EmptyFeatureState()

    public init() {}

    public static func processRecord(
        _ event: KeyEvent,
        state: inout EmptyFeatureState,
        context: inout FirmwareContext
    ) -> KeyEventDisposition {
        if event.isPressed,
            context.highestLayer == 4,
            isRGBControl(event.keycode)
        {
            context.rgbPreviewMode = true
        }
        return .continueProcessing
    }

    public static func layerStateSet(
        _ layerState: inout UInt32,
        state: inout EmptyFeatureState,
        context: inout FirmwareContext
    ) {
        if highestLayer(layerState) != 4 { context.rgbPreviewMode = false }
    }

    public static func rgbMatrixIndicators(
        _ range: RGBIndicatorRange,
        state: inout EmptyFeatureState,
        context: inout FirmwareContext
    ) -> Bool {
#if hasFeature(Embedded)
        // QMK's split RGB task can hand the right USB master an empty shard
        // encoded with reversed bounds. C indicator loops naturally skip it,
        // while constructing Swift's half-open Range would trap.
        guard !range.isEmpty else { return false }

        let layer = context.highestLayer
        guard (context.unstyledLayerMask & (1 << layer)) == 0 else { return false }
        if context.pointerFeatureActive, layer == 4, context.rgbPreviewMode { return false }

        if layer != context.preservesBaseRGBOnLayer {
            for led in range.lowerBound..<range.upperBound {
                obbut_platform_rgb_set_color(led, 0, 0, 0)
            }
        }
        if context.pointerFeatureActive, layer == 5 {
            let red: UInt8 = context.pointerDragLockActive ? 48 : 0
            let green: UInt8 = context.pointerDragLockActive ? 0 : 24
            let blue: UInt8 = context.pointerDragLockActive ? 0 : 32
            for led in range.lowerBound..<range.upperBound {
                obbut_platform_rgb_set_color(led, red, green, blue)
            }
        }

        let rows = obbut_platform_matrix_row_count()
        let columns = obbut_platform_matrix_column_count()
        for row in UInt8(0)..<rows {
            for column in UInt8(0)..<columns {
                let led = obbut_platform_matrix_led_index(row, column)
                guard led >= range.lowerBound,
                    led < range.upperBound,
                    led != UInt8.max
                else {
                    continue
                }
                let styleID = obbut_platform_swift_style_id(layer, row, column)
                if context.pointerFeatureActive,
                    layer == 5,
                    obbut_platform_swift_keycode(layer, row, column)
                        == QMKKeycode.pointerDragLock.rawValue,
                    !context.pointerDragLockActive
                {
                    obbut_platform_rgb_set_color(led, 255, 128, 0)
                    continue
                }
                if styleID != 0 {
                    let color = obbut_platform_swift_style_color(layer, row, column)
                    obbut_platform_rgb_set_color(
                        led,
                        UInt8(truncatingIfNeeded: color >> 16),
                        UInt8(truncatingIfNeeded: color >> 8),
                        UInt8(truncatingIfNeeded: color)
                    )
                } else if context.showsOperatingSystemIndicator, layer == 4 {
                    let baseKeycode = obbut_platform_swift_keycode(0, row, column)
                    let operatingSystemKeycode: UInt16 = context.isWindows ? 0x00E0 : 0x00E3
                    if baseKeycode == operatingSystemKeycode {
                        obbut_platform_rgb_set_color(led, 255, 255, 255)
                    }
                }
            }
        }
#endif
        return false
    }
}

fileprivate extension ObbutLayerLighting {
    static func isRGBControl(_ keycode: UInt16) -> Bool {
        keycode == QMKKeycode.rgbMatrixToggle.rawValue
            || keycode == QMKKeycode.rgbMatrixNext.rawValue
            || keycode == QMKKeycode.rgbMatrixPrevious.rawValue
            || keycode == QMKKeycode.rgbMatrixHueUp.rawValue
            || keycode == QMKKeycode.rgbMatrixHueDown.rawValue
            || keycode == QMKKeycode.rgbMatrixSaturationUp.rawValue
            || keycode == QMKKeycode.rgbMatrixSaturationDown.rawValue
            || keycode == QMKKeycode.rgbMatrixValueUp.rawValue
            || keycode == QMKKeycode.rgbMatrixValueDown.rawValue
            || keycode == QMKKeycode.keychronRGBToggle.rawValue
            || keycode == QMKKeycode.keychronRGBValueUp.rawValue
            || keycode == QMKKeycode.keychronRGBValueDown.rawValue
            || keycode == QMKKeycode.keychronRGBSpeedUp.rawValue
            || keycode == QMKKeycode.keychronRGBSpeedDown.rawValue
            || keycode == Key.rgbToggle.keycode.rawValue
            || keycode == Key.rgbNext.keycode.rawValue
            || keycode == Key.rgbPrevious.keycode.rawValue
            || keycode == Key.rgbHueUp.keycode.rawValue
            || keycode == Key.rgbHueDown.keycode.rawValue
            || keycode == Key.rgbSaturationUp.keycode.rawValue
            || keycode == Key.rgbSaturationDown.keycode.rawValue
            || keycode == Key.rgbValueUp.keycode.rawValue
            || keycode == Key.rgbValueDown.keycode.rawValue
    }

    static func highestLayer(_ state: UInt32) -> UInt8 {
        guard state != 0 else { return 0 }
        return UInt8(31 - state.leadingZeroBitCount)
    }
}
