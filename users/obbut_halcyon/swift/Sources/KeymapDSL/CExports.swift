// C Exports for Swift-QMK Integration
// These functions are exported via @_cdecl to be called from C code
// SPDX-License-Identifier: GPL-2.0-or-later

// MARK: - Keyboard Initialization

/// Called once at keyboard startup
/// Exported to C as: void swift_keyboard_post_init(void)
@_cdecl("swift_keyboard_post_init")
public func swiftKeyboardPostInit() {
    keyboardInit()
}

// MARK: - Housekeeping

/// Called periodically from the main loop
/// Exported to C as: void swift_housekeeping_task(void)
@_cdecl("swift_housekeeping_task")
public func swiftHousekeepingTask() {
    housekeepingTask()
}

// MARK: - Key Processing

/// Process a key event
/// Exported to C as: bool swift_process_record(uint16_t keycode, bool pressed, uint8_t row, uint8_t col)
@_cdecl("swift_process_record")
public func swiftProcessRecord(keycode: UInt16, pressed: Bool, row: UInt8, col: UInt8) -> Bool {
    let event = KeyEvent(pressed: pressed, row: row, col: col)
    return processRecord(keycode: keycode, event: event)
}

// MARK: - Layer State

/// Handle layer state changes
/// Exported to C as: layer_state_t swift_layer_state_set(layer_state_t state)
@_cdecl("swift_layer_state_set")
public func swiftLayerStateSet(state: layer_state_t) -> layer_state_t {
    return layerStateSet(state: state)
}

// MARK: - RGB Matrix Indicators

/// Update RGB matrix indicators based on current layer
/// Exported to C as: bool swift_rgb_matrix_indicators(uint8_t led_min, uint8_t led_max)
@_cdecl("swift_rgb_matrix_indicators")
public func swiftRGBMatrixIndicators(ledMin: UInt8, ledMax: UInt8) -> Bool {
    return updateRGBIndicators(ledMin: ledMin, ledMax: ledMax)
}

// MARK: - RGB Preview Mode Accessors

/// Get RGB preview mode state (called from C glue layer)
/// Exported to C as: bool swift_get_rgb_preview_mode(void)
/// Note: The actual getter is implemented in swift_glue.c for split keyboard sync

/// Set RGB preview mode state (called from C glue layer)
/// Note: The actual setter is implemented in swift_glue.c for split keyboard sync

// MARK: - Keymap Export

/// The keymap data exported for QMK
/// This provides the keymap array that QMK uses for key lookups
///
/// Note: In embedded Swift, we can't easily export a PROGMEM array directly.
/// Instead, the C glue layer defines a minimal keymaps array, and the actual
/// key processing happens in Swift via process_record_user.
///
/// For keyboards that need the keymap array (e.g., for RGB indicators that
/// look up keycodes), we provide accessor functions.

/// Get keycode at a specific position in a layer
/// Exported to C as: uint16_t swift_get_keycode(uint8_t layer, uint8_t row, uint8_t col)
@_cdecl("swift_get_keycode")
public func swiftGetKeycode(layer: UInt8, row: UInt8, col: UInt8) -> UInt16 {
    // This would look up the keycode from the Swift keymap
    // For now, we delegate to the C keymap via the bridging header
    return glue_keymap_key_to_keycode(layer, row, col)
}

// MARK: - Active Keymap

/// Get the currently active keymap based on keyboard type
/// The keymap is selected at compile time via conditional compilation

#if KYRIA_KEYBOARD
/// The active keymap for Kyria
public var activeKeymap: Keymap {
    kyriaKeymap
}
#elseif ELORA_KEYBOARD
/// The active keymap for Elora
public var activeKeymap: Keymap {
    eloraKeymap
}
#else
/// Default to Kyria keymap if keyboard type not specified
public var activeKeymap: Keymap {
    kyriaKeymap
}
#endif
