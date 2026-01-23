// Key processing logic for QMK keyboard firmware
// This replaces the C logic in obbut_halcyon.c
// SPDX-License-Identifier: GPL-2.0-or-later

// MARK: - State

/// Global state for keyboard behavior
/// Note: In embedded Swift, we use simple global variables instead of classes
/// because class instances require heap allocation

/// Current RGB preview mode state
var rgbPreviewMode = false

/// Last sync time for RGB preview mode
var lastRGBSyncTime: UInt32 = 0

/// Last synced RGB preview mode value
var lastRGBPreviewMode = false

// MARK: - C Bridge Functions (imported via bridging header)

// QMK functions are imported directly via BridgingHeader.h which includes quantum.h
// Glue functions are only used for C macros that Swift can't see

/// Get the current highest active layer
@inline(__always)
func getCurrentLayer() -> Layer {
    // glue_get_highest_layer wraps the get_highest_layer() macro
    // glue_get_layer_state wraps the layer_state global variable
    let layerValue = glue_get_highest_layer(glue_get_layer_state())
    return Layer(rawValue: layerValue)
}

/// Check if the detected OS is Windows
@inline(__always)
func isWindows() -> Bool {
    // detected_host_os() is a real function, called directly
    return detected_host_os() == OS_WINDOWS
}

/// Check if this is the master half of a split keyboard
@inline(__always)
func isMaster() -> Bool {
    // is_keyboard_master() is a real function, called directly
    return is_keyboard_master()
}

// MARK: - Key Processing

/// Process a key event
/// Returns true to continue processing, false to consume the key
///
/// This is called from the C glue layer via @_cdecl
func processRecord(keycode: UInt16, event: KeyEvent) -> Bool {
    let key = Keycode(rawValue: keycode)
    let layer = getCurrentLayer()

    // When pressing RGB control keys on Function layer, enable preview mode
    if event.pressed && layer == .function {
        if isRGBControlKey(key) {
            rgbPreviewMode = true
        }
    }

    // OS-specific key swaps for Windows
    if isWindows() {
        return processWindowsKeySwap(keycode: key, event: event)
    }

    return true
}

/// Check if a keycode is an RGB control key
@inline(__always)
func isRGBControlKey(_ key: Keycode) -> Bool {
    switch key {
    case .rgbToggle, .rgbNext, .rgbPrev,
         .rgbHueUp, .rgbHueDown,
         .rgbSatUp, .rgbSatDown,
         .rgbValUp, .rgbValDown:
        return true
    default:
        return false
    }
}

/// Handle Windows-specific key swaps
func processWindowsKeySwap(keycode key: Keycode, event: KeyEvent) -> Bool {
    switch key {
    // Mouse button 1 toggles QWERTY layer on Elora (for gaming mode)
    // This is only enabled on Elora via conditional compilation
    #if ELORA_KEYBOARD
    case .mouseButton1:
        if event.pressed {
            // Toggle QWERTY layer
            layer_invert(Layer.qwerty.rawValue)
        }
        return false
    #endif

    // Screenshot: send Print Screen instead of macOS shortcut
    case .screenshot:
        if event.pressed {
            register_code(0x46)  // KC_PSCR
        } else {
            unregister_code(0x46)
        }
        return false

    // Swap Ctrl and Cmd on Windows
    case .leftControl:
        if event.pressed {
            register_code(0xE3)  // KC_LGUI
        } else {
            unregister_code(0xE3)
        }
        return false

    case .leftGui:
        if event.pressed {
            register_code(0xE0)  // KC_LCTL
        } else {
            unregister_code(0xE0)
        }
        return false

    default:
        return true
    }
}

// MARK: - Layer State

/// Handle layer state changes
/// Returns the new layer state
func layerStateSet(state: UInt32) -> UInt32 {
    let layer = Layer(rawValue: glue_get_highest_layer(state))

    // Reset preview mode when leaving Function layer
    if layer != .function {
        rgbPreviewMode = false
    }

    return state
}

// MARK: - Housekeeping

/// Periodic housekeeping task (called from main loop)
func housekeepingTask() {
    // Sync RGB preview mode to slave half
    if isMaster() {
        let currentTime = timer_read32()

        // Sync when state changes or every 500ms
        if rgbPreviewMode != lastRGBPreviewMode || timer_elapsed32(lastRGBSyncTime) > 500 {
            // Note: The actual sync is handled by the C glue layer
            // which accesses the rgb_preview_mode variable
            lastRGBPreviewMode = rgbPreviewMode
            lastRGBSyncTime = currentTime
        }
    }
}

// MARK: - Initialization

/// Initialize keyboard (called once at startup)
func keyboardInit() {
    // The C glue layer handles transaction registration
    // This function can be used for Swift-specific initialization

    // Optional: Flash LEDs cyan briefly to indicate Swift code is running
    // This serves as visible proof that Swift is executing on the MCU
    #if RGB_MATRIX_ENABLE
    // Flash all LEDs cyan for 100ms
    for i: UInt8 in 0..<64 {
        rgb_matrix_set_color(Int32(i), 0, 220, 220)
    }
    // The main RGB effect will take over after a short delay
    #endif
}
