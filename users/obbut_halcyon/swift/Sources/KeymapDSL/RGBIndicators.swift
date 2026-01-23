// RGB Matrix layer indicators for QMK keyboard firmware
// This replaces the C RGB indicator logic in obbut_halcyon.c
// SPDX-License-Identifier: GPL-2.0-or-later

// MARK: - RGB Layer Indicators

/// Update RGB matrix indicators based on current layer
/// Returns false to indicate indicators were set (don't run default effect)
func updateRGBIndicators(ledMin: UInt8, ledMax: UInt8) -> Bool {
    let layer = getCurrentLayer()

    // Skip Function layer indicators if in preview mode
    if layer == .function && rgbPreviewMode {
        return false  // Let the RGB effect show
    }

    switch layer {
    case .lower:
        return updateLowerLayerIndicators(ledMin: ledMin, ledMax: ledMax)

    case .raise:
        return updateRaiseLayerIndicators(ledMin: ledMin, ledMax: ledMax)

    case .function:
        return updateFunctionLayerIndicators(ledMin: ledMin, ledMax: ledMax)

    case .qwerty:
        return updateQWERTYLayerIndicators(ledMin: ledMin, ledMax: ledMax)

    default:
        return false  // Let default RGB effect run
    }
}

// MARK: - Lower Layer (Navigation)

/// Lower layer: Arrow keys magenta, Delete/Backspace orange
func updateLowerLayerIndicators(ledMin: UInt8, ledMax: UInt8) -> Bool {
    // Turn off all LEDs first
    clearLEDs(ledMin: ledMin, ledMax: ledMax)

    let matrixRows = glue_matrix_rows()
    let matrixCols = glue_matrix_cols()

    // Scan all keys and highlight based on keycode
    for row in 0..<matrixRows {
        for col in 0..<matrixCols {
            let ledIndex = glue_rgb_matrix_get_led_index(row, col)

            if glue_led_index_valid(ledIndex, ledMin, ledMax) {
                let keycode = glue_keymap_key_to_keycode(Layer.lower.rawValue, row, col)

                // Arrow keys: magenta
                if keycode == Keycode.left.rawValue ||
                   keycode == Keycode.down.rawValue ||
                   keycode == Keycode.up.rawValue ||
                   keycode == Keycode.right.rawValue {
                    setLEDColor(ledIndex, RGB.magenta)
                }
                // Delete/Backspace: orange
                else if keycode == Keycode.delete.rawValue ||
                        keycode == Keycode.backspace.rawValue {
                    setLEDColor(ledIndex, RGB.orange)
                }
            }
        }
    }

    return false
}

// MARK: - Raise Layer (Symbols/Numbers)

/// Raise layer: Numbers blue, symbols yellow
func updateRaiseLayerIndicators(ledMin: UInt8, ledMax: UInt8) -> Bool {
    clearLEDs(ledMin: ledMin, ledMax: ledMax)

    let matrixRows = glue_matrix_rows()
    let matrixCols = glue_matrix_cols()

    for row in 0..<matrixRows {
        for col in 0..<matrixCols {
            let ledIndex = glue_rgb_matrix_get_led_index(row, col)

            if glue_led_index_valid(ledIndex, ledMin, ledMax) {
                let keycode = glue_keymap_key_to_keycode(Layer.raise.rawValue, row, col)

                // Number keys 0-9: blue
                if isNumberKey(keycode) {
                    setLEDColor(ledIndex, RGB.blue)
                }
                // Symbol keys: yellow
                else if isSymbolKey(keycode) {
                    setLEDColor(ledIndex, RGB.yellow)
                }
            }
        }
    }

    return false
}

// MARK: - Function Layer (F-keys, RGB, Boot)

/// Function layer: F-keys cyan, RGB controls green, Boot keys red
func updateFunctionLayerIndicators(ledMin: UInt8, ledMax: UInt8) -> Bool {
    clearLEDs(ledMin: ledMin, ledMax: ledMax)

    let matrixRows = glue_matrix_rows()
    let matrixCols = glue_matrix_cols()

    // Determine which key to highlight based on OS (the "primary" modifier)
    // macOS: Command (KC_LGUI), Windows: Control (KC_LCTL)
    let osIndicatorKeycode = isWindows() ? Keycode.leftControl.rawValue : Keycode.leftGui.rawValue

    for row in 0..<matrixRows {
        for col in 0..<matrixCols {
            let ledIndex = glue_rgb_matrix_get_led_index(row, col)

            if glue_led_index_valid(ledIndex, ledMin, ledMax) {
                let keycode = glue_keymap_key_to_keycode(Layer.function.rawValue, row, col)
                let defaultKeycode = glue_keymap_key_to_keycode(Layer.default.rawValue, row, col)

                // F-keys F1-F15: cyan
                if isFunctionKey(keycode) {
                    setLEDColor(ledIndex, RGB.cyan)
                }
                // RGB controls increase: bright green
                else if isRGBIncreaseKey(keycode) {
                    setLEDColor(ledIndex, RGB.green)
                }
                // RGB controls decrease: dark green
                else if isRGBDecreaseKey(keycode) {
                    setLEDColor(ledIndex, RGB.darkGreen)
                }
                // Boot keys: red
                else if keycode == Keycode.bootloader.rawValue {
                    setLEDColor(ledIndex, RGB.red)
                }
                // QWERTY toggle key: purple
                else if keycode == Keycode.toggleQwerty.rawValue {
                    setLEDColor(ledIndex, RGB.purple)
                }
                // OS indicator: white on primary modifier key
                else if defaultKeycode == osIndicatorKeycode {
                    setLEDColor(ledIndex, RGB.white)
                }
            }
        }
    }

    return false
}

// MARK: - QWERTY Layer (Gaming)

/// QWERTY layer: WASD and left thumb cluster highlighted in purple
/// Unlike other layers, keeps the RGB effect running underneath
func updateQWERTYLayerIndicators(ledMin: UInt8, ledMax: UInt8) -> Bool {
    // Don't clear LEDs - let the effect show through

    let matrixRows = glue_matrix_rows()
    let matrixCols = glue_matrix_cols()

    for row in 0..<matrixRows {
        for col in 0..<matrixCols {
            let ledIndex = glue_rgb_matrix_get_led_index(row, col)

            if glue_led_index_valid(ledIndex, ledMin, ledMax) {
                let keycode = glue_keymap_key_to_keycode(Layer.qwerty.rawValue, row, col)

                // WASD keys + left thumb cluster: bright purple
                if keycode == Keycode.w.rawValue ||
                   keycode == Keycode.a.rawValue ||
                   keycode == Keycode.s.rawValue ||
                   keycode == Keycode.d.rawValue ||
                   keycode == Keycode.leftControl.rawValue ||
                   keycode == Keycode.leftAlt.rawValue ||
                   keycode == Keycode.space.rawValue {
                    setLEDColor(ledIndex, RGB.purple)
                }
            }
        }
    }

    return false
}

// MARK: - Helper Functions

/// Clear all LEDs in the given range
@inline(__always)
func clearLEDs(ledMin: UInt8, ledMax: UInt8) {
    for i in ledMin..<ledMax {
        glue_rgb_matrix_set_color(i, 0, 0, 0)
    }
}

/// Set LED color
@inline(__always)
func setLEDColor(_ ledIndex: UInt8, _ color: RGB) {
    glue_rgb_matrix_set_color(ledIndex, color.r, color.g, color.b)
}

/// Check if keycode is a number key (0-9)
@inline(__always)
func isNumberKey(_ keycode: UInt16) -> Bool {
    // KC_1 through KC_0 (note: KC_0 is after KC_9 in USB HID)
    return keycode >= Keycode._1.rawValue && keycode <= Keycode._0.rawValue
}

/// Check if keycode is a symbol key
@inline(__always)
func isSymbolKey(_ keycode: UInt16) -> Bool {
    let key = Keycode(rawValue: keycode)
    switch key {
    case .grave, .exclaim, .at, .hash, .dollar, .percent, .circumflex,
         .leftBracket, .rightBracket, .leftParen, .rightParen,
         .leftCurly, .rightCurly, .colon, .minus, .plus, .equal,
         .dot, .backslash:
        return true
    default:
        return false
    }
}

/// Check if keycode is an F-key (F1-F15)
@inline(__always)
func isFunctionKey(_ keycode: UInt16) -> Bool {
    return (keycode >= Keycode.f1.rawValue && keycode <= Keycode.f12.rawValue) ||
           (keycode >= Keycode.f13.rawValue && keycode <= Keycode.f15.rawValue)
}

/// Check if keycode is an RGB increase control
@inline(__always)
func isRGBIncreaseKey(_ keycode: UInt16) -> Bool {
    let key = Keycode(rawValue: keycode)
    switch key {
    case .rgbToggle, .rgbNext, .rgbHueUp, .rgbSatUp, .rgbValUp:
        return true
    default:
        return false
    }
}

/// Check if keycode is an RGB decrease control
@inline(__always)
func isRGBDecreaseKey(_ keycode: UInt16) -> Bool {
    let key = Keycode(rawValue: keycode)
    switch key {
    case .rgbPrev, .rgbHueDown, .rgbSatDown, .rgbValDown:
        return true
    default:
        return false
    }
}
