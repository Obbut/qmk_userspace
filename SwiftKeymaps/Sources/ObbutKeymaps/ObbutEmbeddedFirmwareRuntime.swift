#if hasFeature(Embedded)
import QMKFirmwareRuntime

/// Allocation-free firmware behavior shared by Obbut keyboards.
enum ObbutEmbeddedFirmwareRuntime {
    /// Board policy selected by the individual firmware module.
    nonisolated(unsafe) fileprivate static var profile: UInt8 = 0
    /// Whether Function-layer RGB controls temporarily reveal the base effect.
    nonisolated(unsafe) fileprivate static var rgbPreviewMode = false
    /// Whether a latched primary-button drag is active.
    nonisolated(unsafe) fileprivate static var pointerDragLockActive = false
    /// The preview state most recently sent to the other split half.
    nonisolated(unsafe) fileprivate static var lastSyncedRGBPreviewMode = false
    /// The drag state most recently sent to the other split half.
    nonisolated(unsafe) fileprivate static var lastSyncedPointerDragLockActive = false
    /// QMK timestamp of the most recent successful split-state send.
    nonisolated(unsafe) fileprivate static var lastSyncTimestamp: UInt32 = 0

    /// Index into the fixed pointer-sensitivity table.
    nonisolated(unsafe) fileprivate static var pointerSensitivityIndex: UInt8 = 2
    /// Index into the fixed drag-scroll divisor table.
    nonisolated(unsafe) fileprivate static var pointerScrollIndex: UInt8 = 2
    /// Whether the momentary scroll key is held.
    nonisolated(unsafe) fileprivate static var pointerScrollHeld = false
    /// Whether the momentary precision key is held.
    nonisolated(unsafe) fileprivate static var pointerSniperHeld = false
    /// The scrolling mode used for the previous pointer report.
    nonisolated(unsafe) fileprivate static var pointerScrollingWasActive = false
    /// Zero before axis selection, one for horizontal, and two for vertical.
    nonisolated(unsafe) fileprivate static var pointerScrollAxis: UInt8 = 0
    /// Fractional horizontal cursor movement carried between reports.
    nonisolated(unsafe) fileprivate static var pointerMouseAccumulatedX: Int32 = 0
    /// Fractional vertical cursor movement carried between reports.
    nonisolated(unsafe) fileprivate static var pointerMouseAccumulatedY: Int32 = 0
    /// Fractional movement carried between scroll reports.
    nonisolated(unsafe) fileprivate static var pointerScrollAccumulated: Int32 = 0
    /// Horizontal motion retained until the dominant scroll axis is known.
    nonisolated(unsafe) fileprivate static var pointerScrollPendingX: Int32 = 0
    /// Vertical motion retained until the dominant scroll axis is known.
    nonisolated(unsafe) fileprivate static var pointerScrollPendingY: Int32 = 0
    /// Absolute horizontal travel used to choose a scroll axis.
    nonisolated(unsafe) fileprivate static var pointerScrollAbsoluteX: UInt16 = 0
    /// Absolute vertical travel used to choose a scroll axis.
    nonisolated(unsafe) fileprivate static var pointerScrollAbsoluteY: UInt16 = 0

    /// Board policy identifier for Kyria.
    fileprivate static let kyriaProfile: UInt8 = 1
    /// Board policy identifier for Elora.
    fileprivate static let eloraProfile: UInt8 = 2
    /// Stable shared QWERTY layer index.
    fileprivate static let qwertyLayer: UInt8 = 1
    /// Stable shared Lower layer index.
    fileprivate static let lowerLayer: UInt8 = 2
    /// Stable shared Raise layer index.
    fileprivate static let raiseLayer: UInt8 = 3
    /// Stable shared Function layer index.
    fileprivate static let functionLayer: UInt8 = 4
    /// Stable Kyria Pointer layer index.
    fileprivate static let pointerLayer: UInt8 = 5

    /// Selects board policy and initializes split-state transport.
    static func postInitialize(profile newProfile: UInt8) {
        profile = newProfile
        obbut_platform_register_split_sync()
    }

    /// Periodically mirrors visual state from the USB master to the other half.
    static func performHousekeeping() {
        guard obbut_platform_is_keyboard_master() != 0 else { return }
        let now = obbut_platform_timer_read32()
        let changed = rgbPreviewMode != lastSyncedRGBPreviewMode
            || pointerDragLockActive != lastSyncedPointerDragLockActive
        guard changed || now &- lastSyncTimestamp > 500 else { return }
        guard obbut_platform_sync_split_state(
            rgbPreviewMode ? 1 : 0,
            pointerDragLockActive ? 1 : 0
        ) != 0 else { return }
        lastSyncedRGBPreviewMode = rgbPreviewMode
        lastSyncedPointerDragLockActive = pointerDragLockActive
        lastSyncTimestamp = now
    }

    /// Handles shared pointer, RGB-preview, and Windows key behavior.
    static func processRecord(kind rawKind: UInt8, pressed: Bool) -> Bool {
        let kind = ObbutEmbeddedKeyKind(rawValue: rawKind) ?? .other
        if profile == kyriaProfile, pressed, !kind.isPointerAction, kind != .modifier {
            setDragLock(false)
            obbut_platform_auto_mouse_reset_trigger()
        }

        switch kind {
        case .pointerScroll:
            pointerScrollHeld = pressed
            resetPointerScroll()
            return false
        case .pointerSniper:
            pointerSniperHeld = pressed
            resetPointerCursor()
            return false
        case .pointerDragLock:
            if pressed { setDragLock(!pointerDragLockActive) }
            return false
        case .pointerSensitivityDown:
            if pressed, pointerSensitivityIndex > 0 {
                pointerSensitivityIndex &-= 1
                resetPointerCursor()
            }
            return false
        case .pointerSensitivityUp:
            if pressed, pointerSensitivityIndex < 4 {
                pointerSensitivityIndex &+= 1
                resetPointerCursor()
            }
            return false
        case .pointerScrollSpeedDown:
            if pressed, pointerScrollIndex > 0 {
                pointerScrollIndex &-= 1
                resetPointerScroll()
            }
            return false
        case .pointerScrollSpeedUp:
            if pressed, pointerScrollIndex < 4 {
                pointerScrollIndex &+= 1
                resetPointerScroll()
            }
            return false
        default:
            break
        }

        if pressed, kind == .rgbControl, obbut_platform_highest_layer() == functionLayer {
            rgbPreviewMode = true
        }

        guard obbut_platform_is_windows() != 0 else { return true }
        if profile == eloraProfile, kind == .pointerLeftClick {
            if pressed { obbut_platform_layer_invert(qwertyLayer) }
            return false
        }
        switch kind {
        case .volumeUp, .volumeDown, .screenshot, .leftControl, .leftCommand:
            obbut_platform_send_override(kind.rawValue, pressed ? 1 : 0)
            return false
        default:
            return true
        }
    }

    /// Applies automatic-pointer policy and clears transient RGB preview state.
    static func layerStateChanged(_ state: UInt32) -> UInt32 {
        var updatedState = state
        if profile == kyriaProfile {
            let stateWithoutPointer = obbut_platform_remove_auto_mouse_layer(updatedState)
            let underlyingLayer = highestLayer(in: stateWithoutPointer)
            let utilityLayerIsActive = underlyingLayer == lowerLayer
                || underlyingLayer == raiseLayer
                || underlyingLayer == functionLayer
            if utilityLayerIsActive {
                setDragLock(false)
                updatedState = obbut_platform_remove_auto_mouse_layer(updatedState)
                obbut_platform_set_auto_mouse_enabled(0)
            } else {
                obbut_platform_set_auto_mouse_enabled(1)
            }
        }
        if highestLayer(in: updatedState) != functionLayer { rgbPreviewMode = false }
        return updatedState
    }

    /// Restores deterministic pointer defaults at pointing-device startup.
    static func initializePointer() {
        pointerSensitivityIndex = 2
        pointerScrollIndex = 2
        pointerScrollHeld = false
        pointerSniperHeld = false
        pointerScrollingWasActive = false
        pointerDragLockActive = false
        resetPointerCursor()
        resetPointerScroll()
        obbut_platform_configure_auto_mouse(pointerLayer)
    }

    /// Applies cursor scaling, sniper mode, dominant-axis scrolling, and drag lock.
    static func transformPointer(
        x: UnsafeMutablePointer<Int8>,
        y: UnsafeMutablePointer<Int8>,
        horizontal: UnsafeMutablePointer<Int8>,
        vertical: UnsafeMutablePointer<Int8>,
        buttons: UnsafeMutablePointer<UInt8>,
        lowerLayerActive: Bool
    ) {
        let scrollingActive = lowerLayerActive || pointerScrollHeld
        if scrollingActive != pointerScrollingWasActive {
            resetPointerScroll()
            pointerScrollingWasActive = scrollingActive
        }

        if scrollingActive {
            let movementX = Int32(x.pointee)
            let movementY = Int32(y.pointee)
            horizontal.pointee = 0
            vertical.pointee = 0
            x.pointee = 0
            y.pointee = 0

            if pointerScrollAxis == 0 {
                pointerScrollPendingX &+= movementX
                pointerScrollPendingY &+= movementY
                pointerScrollAbsoluteX &+= absoluteMovement(movementX)
                pointerScrollAbsoluteY &+= absoluteMovement(movementY)
                if pointerScrollAbsoluteX &+ pointerScrollAbsoluteY >= 6 {
                    pointerScrollAxis = pointerScrollAbsoluteX >= pointerScrollAbsoluteY ? 1 : 2
                    pointerScrollAccumulated = pointerScrollAxis == 1
                        ? pointerScrollPendingX
                        : pointerScrollPendingY
                }
            } else {
                pointerScrollAccumulated &+= pointerScrollAxis == 1 ? movementX : movementY
            }

            if pointerScrollAxis != 0 {
                let divisor = Int32(scrollDivisor(at: pointerScrollIndex))
                let units = pointerScrollAccumulated / divisor
                pointerScrollAccumulated &-= units * divisor
                if pointerScrollAxis == 1 {
                    horizontal.pointee = Int8(truncatingIfNeeded: units)
                } else {
                    vertical.pointee = Int8(truncatingIfNeeded: -units)
                }
            }
        } else {
            var numerator = Int32(sensitivity(at: pointerSensitivityIndex))
            var denominator: Int32 = 100
            if pointerSniperHeld {
                numerator *= 35
                denominator *= 100
            }
            pointerMouseAccumulatedX &+= Int32(x.pointee) * numerator
            pointerMouseAccumulatedY &+= Int32(y.pointee) * numerator
            let outputX = pointerMouseAccumulatedX / denominator
            let outputY = pointerMouseAccumulatedY / denominator
            x.pointee = Int8(truncatingIfNeeded: outputX)
            y.pointee = Int8(truncatingIfNeeded: outputY)
            pointerMouseAccumulatedX &-= outputX * denominator
            pointerMouseAccumulatedY &-= outputY * denominator
        }

        if pointerDragLockActive { buttons.pointee |= 1 }
    }

    /// Accepts visual state received from the USB-master half.
    static func receiveSplitState(rgbPreview: Bool, dragLock: Bool) {
        rgbPreviewMode = rgbPreview
        pointerDragLockActive = dragLock
    }

    /// Starts RGB preview after the companion applies persistent RGB settings.
    static func rgbSettingsApplied() {
        rgbPreviewMode = obbut_platform_highest_layer() == functionLayer
    }

    /// Updates drag-lock and QMK automatic-pointer latch state together.
    fileprivate static func setDragLock(_ active: Bool) {
        guard pointerDragLockActive != active else { return }
        pointerDragLockActive = active
        if !active { obbut_platform_release_left_pointer_button() }
        if (obbut_platform_auto_mouse_toggle_state() != 0) != active {
            obbut_platform_toggle_auto_mouse()
        }
    }

    /// Clears fractional cursor movement.
    fileprivate static func resetPointerCursor() {
        pointerMouseAccumulatedX = 0
        pointerMouseAccumulatedY = 0
    }

    /// Clears axis selection and fractional scroll movement.
    fileprivate static func resetPointerScroll() {
        pointerScrollAxis = 0
        pointerScrollAccumulated = 0
        pointerScrollPendingX = 0
        pointerScrollPendingY = 0
        pointerScrollAbsoluteX = 0
        pointerScrollAbsoluteY = 0
    }

    /// Returns the highest set bit in a QMK layer-state mask.
    fileprivate static func highestLayer(in state: UInt32) -> UInt8 {
        guard state != 0 else { return 0 }
        var value = state
        var layer: UInt8 = 0
        while value > 1 {
            value >>= 1
            layer &+= 1
        }
        return layer
    }

    /// Converts signed pointer movement to its unsigned magnitude.
    fileprivate static func absoluteMovement(_ movement: Int32) -> UInt16 {
        UInt16(truncatingIfNeeded: movement < 0 ? -movement : movement)
    }

    /// Returns the percentage cursor scale for a sensitivity index.
    fileprivate static func sensitivity(at index: UInt8) -> UInt8 {
        switch index {
        case 0: 40
        case 1: 55
        case 2: 67
        case 3: 85
        default: 100
        }
    }

    /// Returns the movement divisor for a drag-scroll speed index.
    fileprivate static func scrollDivisor(at index: UInt8) -> UInt8 {
        switch index {
        case 0: 48
        case 1: 40
        case 2: 32
        case 3: 24
        default: 16
        }
    }
}

/// Compact key classifications emitted by generated QMK glue.
fileprivate enum ObbutEmbeddedKeyKind: UInt8 {
    case other = 0
    case pointerScroll = 1
    case pointerSniper = 2
    case pointerDragLock = 3
    case pointerSensitivityDown = 4
    case pointerSensitivityUp = 5
    case pointerScrollSpeedDown = 6
    case pointerScrollSpeedUp = 7
    case pointerLeftClick = 8
    case pointerRightClick = 9
    case pointerMiddleClick = 10
    case browserBack = 11
    case browserForward = 12
    case rgbControl = 20
    case volumeUp = 30
    case volumeDown = 31
    case screenshot = 32
    case leftControl = 33
    case leftCommand = 34
    case modifier = 40

    /// Whether the action should keep the automatic pointer layer active.
    var isPointerAction: Bool { rawValue >= 1 && rawValue <= 12 }
}

/// Initializes shared Obbut behavior through the generated C ABI.
@c @implementation
func obbut_swift_post_init(_ profile: UInt8) {
    ObbutEmbeddedFirmwareRuntime.postInitialize(profile: profile)
}

/// Runs shared Obbut housekeeping through the generated C ABI.
@c @implementation
func obbut_swift_housekeeping() {
    ObbutEmbeddedFirmwareRuntime.performHousekeeping()
}

/// Handles one classified key event through the generated C ABI.
@c @implementation
func obbut_swift_process_record(_ kind: UInt8, _ pressed: UInt8) -> UInt8 {
    ObbutEmbeddedFirmwareRuntime.processRecord(kind: kind, pressed: pressed != 0) ? 1 : 0
}

/// Transforms QMK layer state through the generated C ABI.
@c @implementation
func obbut_swift_layer_state_changed(_ state: UInt32) -> UInt32 {
    ObbutEmbeddedFirmwareRuntime.layerStateChanged(state)
}

/// Initializes the Kyria pointer engine through the generated C ABI.
@c @implementation
func obbut_swift_pointing_device_init() {
    ObbutEmbeddedFirmwareRuntime.initializePointer()
}

/// Transforms one QMK pointer report through primitive ABI fields.
@c @implementation
func obbut_swift_transform_pointer(
    _ x: UnsafeMutablePointer<Int8>,
    _ y: UnsafeMutablePointer<Int8>,
    _ horizontal: UnsafeMutablePointer<Int8>,
    _ vertical: UnsafeMutablePointer<Int8>,
    _ buttons: UnsafeMutablePointer<UInt8>,
    _ lowerLayerActive: UInt8
) {
    ObbutEmbeddedFirmwareRuntime.transformPointer(
        x: x,
        y: y,
        horizontal: horizontal,
        vertical: vertical,
        buttons: buttons,
        lowerLayerActive: lowerLayerActive != 0
    )
}

/// Receives mirrored visual state from the other split half.
@c @implementation
func obbut_swift_receive_split_state(_ rgbPreviewMode: UInt8, _ dragLockActive: UInt8) {
    ObbutEmbeddedFirmwareRuntime.receiveSplitState(
        rgbPreview: rgbPreviewMode != 0,
        dragLock: dragLockActive != 0
    )
}

/// Returns whether Function-layer RGB preview is active.
@c @implementation
func obbut_swift_rgb_preview_mode() -> UInt8 {
    ObbutEmbeddedFirmwareRuntime.rgbPreviewMode ? 1 : 0
}

/// Returns whether pointer drag lock is active.
@c @implementation
func obbut_swift_pointer_drag_lock_active() -> UInt8 {
    ObbutEmbeddedFirmwareRuntime.pointerDragLockActive ? 1 : 0
}

/// Notifies shared behavior after the companion applies RGB settings.
@c @implementation
func obbut_swift_rgb_settings_applied() {
    ObbutEmbeddedFirmwareRuntime.rgbSettingsApplied()
}
#endif
