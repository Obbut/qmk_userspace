/// Standard QMK key actions available to every keymap.
public extension Key {
    static var no: Key { standard("KC_NO", hidValue: 0x0000) }
    static var transparent: Key { standard("KC_TRNS", hidValue: 0x0001) }
    static var a: Key { standard("KC_A", hidValue: 0x0004) }
    static var b: Key { standard("KC_B", hidValue: 0x0005) }
    static var c: Key { standard("KC_C", hidValue: 0x0006) }
    static var d: Key { standard("KC_D", hidValue: 0x0007) }
    static var e: Key { standard("KC_E", hidValue: 0x0008) }
    static var f: Key { standard("KC_F", hidValue: 0x0009) }
    static var g: Key { standard("KC_G", hidValue: 0x000A) }
    static var h: Key { standard("KC_H", hidValue: 0x000B) }
    static var i: Key { standard("KC_I", hidValue: 0x000C) }
    static var j: Key { standard("KC_J", hidValue: 0x000D) }
    static var k: Key { standard("KC_K", hidValue: 0x000E) }
    static var l: Key { standard("KC_L", hidValue: 0x000F) }
    static var m: Key { standard("KC_M", hidValue: 0x0010) }
    static var n: Key { standard("KC_N", hidValue: 0x0011) }
    static var o: Key { standard("KC_O", hidValue: 0x0012) }
    static var p: Key { standard("KC_P", hidValue: 0x0013) }
    static var q: Key { standard("KC_Q", hidValue: 0x0014) }
    static var r: Key { standard("KC_R", hidValue: 0x0015) }
    static var s: Key { standard("KC_S", hidValue: 0x0016) }
    static var t: Key { standard("KC_T", hidValue: 0x0017) }
    static var u: Key { standard("KC_U", hidValue: 0x0018) }
    static var v: Key { standard("KC_V", hidValue: 0x0019) }
    static var w: Key { standard("KC_W", hidValue: 0x001A) }
    static var x: Key { standard("KC_X", hidValue: 0x001B) }
    static var y: Key { standard("KC_Y", hidValue: 0x001C) }
    static var z: Key { standard("KC_Z", hidValue: 0x001D) }
    static var one: Key { standard("KC_1", hidValue: 0x001E) }
    static var two: Key { standard("KC_2", hidValue: 0x001F) }
    static var three: Key { standard("KC_3", hidValue: 0x0020) }
    static var four: Key { standard("KC_4", hidValue: 0x0021) }
    static var five: Key { standard("KC_5", hidValue: 0x0022) }
    static var six: Key { standard("KC_6", hidValue: 0x0023) }
    static var seven: Key { standard("KC_7", hidValue: 0x0024) }
    static var eight: Key { standard("KC_8", hidValue: 0x0025) }
    static var nine: Key { standard("KC_9", hidValue: 0x0026) }
    static var zero: Key { standard("KC_0", hidValue: 0x0027) }
    static var `return`: Key { standard("KC_ENT", hidValue: 0x0028) }
    static var escape: Key { standard("KC_ESC", hidValue: 0x0029) }
    static var backspace: Key { standard("KC_BSPC", hidValue: 0x002A) }
    static var tab: Key { standard("KC_TAB", hidValue: 0x002B) }
    static var space: Key { standard("KC_SPC", hidValue: 0x002C) }
    static var minus: Key { standard("KC_MINS", hidValue: 0x002D) }
    static var equal: Key { standard("KC_EQL", hidValue: 0x002E) }
    static var leftBracket: Key { standard("KC_LBRC", hidValue: 0x002F) }
    static var rightBracket: Key { standard("KC_RBRC", hidValue: 0x0030) }
    static var backslash: Key { standard("KC_BSLS", hidValue: 0x0031) }
    static var semicolon: Key { standard("KC_SCLN", hidValue: 0x0033) }
    static var quote: Key { standard("KC_QUOT", hidValue: 0x0034) }
    static var grave: Key { standard("KC_GRV", hidValue: 0x0035) }
    static var comma: Key { standard("KC_COMM", hidValue: 0x0036) }
    static var period: Key { standard("KC_DOT", hidValue: 0x0037) }
    static var slash: Key { standard("KC_SLSH", hidValue: 0x0038) }
    static var printScreen: Key { standard("KC_PSCR", hidValue: 0x0046) }
    static var delete: Key { standard("KC_DEL", hidValue: 0x004C) }
    static var right: Key { standard("KC_RGHT", hidValue: 0x004F) }
    static var left: Key { standard("KC_LEFT", hidValue: 0x0050) }
    static var down: Key { standard("KC_DOWN", hidValue: 0x0051) }
    static var up: Key { standard("KC_UP", hidValue: 0x0052) }
    static var leftControl: Key { standard("KC_LCTL", hidValue: 0x00E0) }
    static var leftShift: Key { standard("KC_LSFT", hidValue: 0x00E1) }
    static var leftOption: Key { standard("KC_LALT", hidValue: 0x00E2) }
    static var leftCommand: Key { standard("KC_LGUI", hidValue: 0x00E3) }
    static var rightControl: Key { standard("KC_RCTL", hidValue: 0x00E4) }
    static var rightShift: Key { standard("KC_RSFT", hidValue: 0x00E5) }
    static var rightOption: Key { standard("KC_RALT", hidValue: 0x00E6) }
    static var rightCommand: Key { standard("KC_RGUI", hidValue: 0x00E7) }
    static var mute: Key { standard("KC_MUTE", hidValue: 0x007F) }
    static var volumeUp: Key { standard("KC_VOLU", hidValue: 0x0080) }
    static var volumeDown: Key { standard("KC_VOLD", hidValue: 0x0081) }
    static var keyboardVolumeUp: Key { standard("KC_KB_VOLUME_UP", hidValue: 0x00A9) }
    static var keyboardVolumeDown: Key { standard("KC_KB_VOLUME_DOWN", hidValue: 0x00AA) }
    static var nextTrack: Key { standard("KC_MNXT", hidValue: 0x00AB) }
    static var previousTrack: Key { standard("KC_MPRV", hidValue: 0x00AC) }
    static var playPause: Key { standard("KC_MPLY", hidValue: 0x00AE) }
    static var bootloader: Key { standard("QK_BOOT", hidValue: 0x7C00) }

    static var exclamation: Key { standard("KC_EXLM", hidValue: 0x021E) }
    static var at: Key { standard("KC_AT", hidValue: 0x021F) }
    static var hash: Key { standard("KC_HASH", hidValue: 0x0220) }
    static var dollar: Key { standard("KC_DLR", hidValue: 0x0221) }
    static var percent: Key { standard("KC_PERC", hidValue: 0x0222) }
    static var caret: Key { standard("KC_CIRC", hidValue: 0x0223) }
    static var leftParenthesis: Key { standard("KC_LPRN", hidValue: 0x0226) }
    static var rightParenthesis: Key { standard("KC_RPRN", hidValue: 0x0227) }
    static var leftBrace: Key { standard("KC_LCBR", hidValue: 0x022F) }
    static var rightBrace: Key { standard("KC_RCBR", hidValue: 0x0230) }
    static var colon: Key { standard("KC_COLN", hidValue: 0x0233) }
    static var plus: Key { standard("KC_PLUS", hidValue: 0x022E) }

    static var rgbToggle: Key { standard("RGB_TOG", hidValue: 0x7842) }
    static var rgbNext: Key { standard("RGB_MOD", hidValue: 0x7843) }
    static var rgbPrevious: Key { standard("RGB_RMOD", hidValue: 0x7844) }
    static var rgbHueUp: Key { standard("RGB_HUI", hidValue: 0x7845) }
    static var rgbHueDown: Key { standard("RGB_HUD", hidValue: 0x7846) }
    static var rgbSaturationUp: Key { standard("RGB_SAI", hidValue: 0x7847) }
    static var rgbSaturationDown: Key { standard("RGB_SAD", hidValue: 0x7848) }
    static var rgbValueUp: Key { standard("RGB_VAI", hidValue: 0x7849) }
    static var rgbValueDown: Key { standard("RGB_VAD", hidValue: 0x784A) }
    static var rgbSpeedUp: Key { standard("RGB_SPI", hidValue: 0x784B) }
    static var rgbSpeedDown: Key { standard("RGB_SPD", hidValue: 0x784C) }

    /// Creates a function key in QMK's supported range.
    ///
    /// - Parameter number: A function-key number from 1 through 24.
    /// - Returns: The matching QMK function key.
    static func function(_ number: Int) -> Key {
        precondition((1...24).contains(number), "QMK function keys are limited to F1...F24.")
        let hidValue: UInt16? = switch number {
        case 1...12: UInt16(0x0039 + number)
        case 13...24: UInt16(0x005B + number)
        default: nil
        }
        return standard("KC_F\(number)", hidValue: hidValue)
    }

    /// Creates one standard QMK key action.
    ///
    /// - Parameters:
    ///   - expression: The QMK C keycode constant.
    ///   - hidValue: The optional basic HID value.
    /// - Returns: A standard key action.
    fileprivate static func standard(_ expression: String, hidValue: UInt16? = nil) -> Key {
        Key(keycode: QMKKeycode(cExpression: expression, hidValue: hidValue))
    }
}
