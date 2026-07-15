import QMKFirmwareRuntime
import QMKKeymapKit

/// Stateful Cirque movement, scrolling, sniper, sensitivity, and drag-lock behavior.
public struct KyriaPointerFeature: FirmwareFeature, Sendable {
    public typealias State = KyriaPointerState
    public static let initialState = KyriaPointerState()

    public init() {}

    public static func postInitialize(state: inout State, context: inout FirmwareContext) {
        context.pointerFeatureActive = true
    }

    public static func processRecord(
        _ event: KeyEvent,
        state: inout State,
        context: inout FirmwareContext
    ) -> KeyEventDisposition {
        if event.isPressed, !isPointerAction(event.keycode), !isModifier(event.keycode) {
            setDragLock(false, state: &state, context: &context)
#if hasFeature(Embedded)
            obbut_platform_auto_mouse_reset_trigger()
#endif
        }

        switch event.keycode {
        case QMKKeycode.pointerScroll.rawValue:
            state.scrollHeld = event.isPressed
            resetScroll(&state)
        case QMKKeycode.pointerSniper.rawValue:
            state.sniperHeld = event.isPressed
            resetCursor(&state)
        case QMKKeycode.pointerDragLock.rawValue:
            if event.isPressed {
                setDragLock(!context.pointerDragLockActive, state: &state, context: &context)
            }
        case QMKKeycode.pointerSensitivityDown.rawValue:
            if event.isPressed, state.sensitivityIndex > 0 {
                state.sensitivityIndex &-= 1
                resetCursor(&state)
            }
        case QMKKeycode.pointerSensitivityUp.rawValue:
            if event.isPressed, state.sensitivityIndex < 4 {
                state.sensitivityIndex &+= 1
                resetCursor(&state)
            }
        case QMKKeycode.pointerScrollSpeedDown.rawValue:
            if event.isPressed, state.scrollIndex > 0 {
                state.scrollIndex &-= 1
                resetScroll(&state)
            }
        case QMKKeycode.pointerScrollSpeedUp.rawValue:
            if event.isPressed, state.scrollIndex < 4 {
                state.scrollIndex &+= 1
                resetScroll(&state)
            }
        default:
            return .continueProcessing
        }
        return .handled
    }

    public static func layerStateSet(
        _ layerState: inout UInt32,
        state: inout State,
        context: inout FirmwareContext
    ) {
#if hasFeature(Embedded)
        let stateWithoutPointer = obbut_platform_remove_auto_mouse_layer(layerState)
        let underlyingLayer = highestLayer(stateWithoutPointer)
        if underlyingLayer == 2 || underlyingLayer == 3 || underlyingLayer == 4 {
            setDragLock(false, state: &state, context: &context)
            layerState = obbut_platform_remove_auto_mouse_layer(layerState)
            obbut_platform_set_auto_mouse_enabled(0)
        } else {
            obbut_platform_set_auto_mouse_enabled(1)
        }
#endif
    }

    public static func pointingDeviceInitialize(
        state: inout State,
        context: inout FirmwareContext
    ) {
        state = initialState
        context.pointerDragLockActive = false
#if hasFeature(Embedded)
        obbut_platform_configure_auto_mouse(5)
#endif
    }

    public static func pointingDeviceTask(
        _ report: inout PointerReport,
        state: inout State,
        context: inout FirmwareContext
    ) {
        let scrolling = (context.layerState & (1 << 2)) != 0 || state.scrollHeld
        if scrolling != state.scrollingWasActive {
            resetScroll(&state)
            state.scrollingWasActive = scrolling
        }

        if scrolling {
            let movementX = Int32(report.x)
            let movementY = Int32(report.y)
            report.horizontal = 0
            report.vertical = 0
            report.x = 0
            report.y = 0

            if state.scrollAxis == 0 {
                state.scrollPendingX &+= movementX
                state.scrollPendingY &+= movementY
                state.scrollAbsoluteX &+= absoluteMovement(movementX)
                state.scrollAbsoluteY &+= absoluteMovement(movementY)
                if state.scrollAbsoluteX &+ state.scrollAbsoluteY >= 6 {
                    state.scrollAxis = state.scrollAbsoluteX >= state.scrollAbsoluteY ? 1 : 2
                    state.scrollAccumulated = state.scrollAxis == 1
                        ? state.scrollPendingX
                        : state.scrollPendingY
                }
            } else {
                state.scrollAccumulated &+= state.scrollAxis == 1 ? movementX : movementY
            }

            if state.scrollAxis != 0 {
                let divisor = Int32(scrollDivisor(state.scrollIndex))
                let units = state.scrollAccumulated / divisor
                state.scrollAccumulated &-= units * divisor
                if state.scrollAxis == 1 {
                    report.horizontal = Int8(truncatingIfNeeded: units)
                } else {
                    report.vertical = Int8(truncatingIfNeeded: -units)
                }
            }
        } else {
            var numerator = Int32(sensitivity(state.sensitivityIndex))
            var denominator: Int32 = 100
            if state.sniperHeld {
                numerator *= 35
                denominator *= 100
            }
            state.mouseAccumulatedX &+= Int32(report.x) * numerator
            state.mouseAccumulatedY &+= Int32(report.y) * numerator
            let outputX = state.mouseAccumulatedX / denominator
            let outputY = state.mouseAccumulatedY / denominator
            report.x = Int8(truncatingIfNeeded: outputX)
            report.y = Int8(truncatingIfNeeded: outputY)
            state.mouseAccumulatedX &-= outputX * denominator
            state.mouseAccumulatedY &-= outputY * denominator
        }

        if context.pointerDragLockActive { report.buttons |= 1 }
    }
}

fileprivate extension KyriaPointerFeature {
    static func isPointerAction(_ keycode: UInt16) -> Bool {
        keycode == QMKKeycode.pointerScroll.rawValue
            || keycode == QMKKeycode.pointerSniper.rawValue
            || keycode == QMKKeycode.pointerDragLock.rawValue
            || keycode == QMKKeycode.pointerSensitivityDown.rawValue
            || keycode == QMKKeycode.pointerSensitivityUp.rawValue
            || keycode == QMKKeycode.pointerScrollSpeedDown.rawValue
            || keycode == QMKKeycode.pointerScrollSpeedUp.rawValue
            || keycode == QMKKeycode.pointerButton1.rawValue
            || keycode == QMKKeycode.pointerButton2.rawValue
            || keycode == QMKKeycode.pointerButton3.rawValue
            || keycode == QMKKeycode.browserBack.rawValue
            || keycode == QMKKeycode.browserForward.rawValue
    }

    static func isModifier(_ keycode: UInt16) -> Bool {
        (0x00E0...0x00E7).contains(keycode) || (0x0100...0x1FFF).contains(keycode)
    }

    static func setDragLock(
        _ active: Bool,
        state: inout State,
        context: inout FirmwareContext
    ) {
        guard context.pointerDragLockActive != active else { return }
        context.pointerDragLockActive = active
#if hasFeature(Embedded)
        if !active { obbut_platform_release_left_pointer_button() }
        if (obbut_platform_auto_mouse_toggle_state() != 0) != active {
            obbut_platform_toggle_auto_mouse()
        }
#endif
    }

    static func resetCursor(_ state: inout State) {
        state.mouseAccumulatedX = 0
        state.mouseAccumulatedY = 0
    }

    static func resetScroll(_ state: inout State) {
        state.scrollAxis = 0
        state.scrollAccumulated = 0
        state.scrollPendingX = 0
        state.scrollPendingY = 0
        state.scrollAbsoluteX = 0
        state.scrollAbsoluteY = 0
    }

    static func highestLayer(_ state: UInt32) -> UInt8 {
        guard state != 0 else { return 0 }
        return UInt8(31 - state.leadingZeroBitCount)
    }

    static func absoluteMovement(_ movement: Int32) -> UInt16 {
        UInt16(truncatingIfNeeded: movement < 0 ? -movement : movement)
    }

    static func sensitivity(_ index: UInt8) -> UInt8 {
        switch index {
        case 0: 40
        case 1: 55
        case 2: 67
        case 3: 85
        default: 100
        }
    }

    static func scrollDivisor(_ index: UInt8) -> UInt8 {
        switch index {
        case 0: 48
        case 1: 40
        case 2: 32
        case 3: 24
        default: 16
        }
    }
}
