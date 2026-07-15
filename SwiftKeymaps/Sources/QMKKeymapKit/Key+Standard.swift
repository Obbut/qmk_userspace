/// Standard QMK key actions available to every keymap.
public extension Key {
    static var no: Key { standard(0x0000) }
    static var transparent: Key { standard(0x0001) }
    static var a: Key { standard(0x0004) }
    static var b: Key { standard(0x0005) }
    static var c: Key { standard(0x0006) }
    static var d: Key { standard(0x0007) }
    static var e: Key { standard(0x0008) }
    static var f: Key { standard(0x0009) }
    static var g: Key { standard(0x000A) }
    static var h: Key { standard(0x000B) }
    static var i: Key { standard(0x000C) }
    static var j: Key { standard(0x000D) }
    static var k: Key { standard(0x000E) }
    static var l: Key { standard(0x000F) }
    static var m: Key { standard(0x0010) }
    static var n: Key { standard(0x0011) }
    static var o: Key { standard(0x0012) }
    static var p: Key { standard(0x0013) }
    static var q: Key { standard(0x0014) }
    static var r: Key { standard(0x0015) }
    static var s: Key { standard(0x0016) }
    static var t: Key { standard(0x0017) }
    static var u: Key { standard(0x0018) }
    static var v: Key { standard(0x0019) }
    static var w: Key { standard(0x001A) }
    static var x: Key { standard(0x001B) }
    static var y: Key { standard(0x001C) }
    static var z: Key { standard(0x001D) }
    static var one: Key { standard(0x001E) }
    static var two: Key { standard(0x001F) }
    static var three: Key { standard(0x0020) }
    static var four: Key { standard(0x0021) }
    static var five: Key { standard(0x0022) }
    static var six: Key { standard(0x0023) }
    static var seven: Key { standard(0x0024) }
    static var eight: Key { standard(0x0025) }
    static var nine: Key { standard(0x0026) }
    static var zero: Key { standard(0x0027) }
    static var `return`: Key { standard(0x0028) }
    static var escape: Key { standard(0x0029) }
    static var backspace: Key { standard(0x002A) }
    static var tab: Key { standard(0x002B) }
    static var space: Key { standard(0x002C) }
    static var minus: Key { standard(0x002D) }
    static var equal: Key { standard(0x002E) }
    static var leftBracket: Key { standard(0x002F) }
    static var rightBracket: Key { standard(0x0030) }
    static var backslash: Key { standard(0x0031) }
    static var semicolon: Key { standard(0x0033) }
    static var quote: Key { standard(0x0034) }
    static var grave: Key { standard(0x0035) }
    static var comma: Key { standard(0x0036) }
    static var period: Key { standard(0x0037) }
    static var slash: Key { standard(0x0038) }
    static var printScreen: Key { standard(0x0046) }
    static var delete: Key { standard(0x004C) }
    static var right: Key { standard(0x004F) }
    static var left: Key { standard(0x0050) }
    static var down: Key { standard(0x0051) }
    static var up: Key { standard(0x0052) }
    static var leftControl: Key { standard(0x00E0) }
    static var leftShift: Key { standard(0x00E1) }
    static var leftOption: Key { standard(0x00E2) }
    static var leftCommand: Key { standard(0x00E3) }
    static var rightControl: Key { standard(0x00E4) }
    static var rightShift: Key { standard(0x00E5) }
    static var rightOption: Key { standard(0x00E6) }
    static var rightCommand: Key { standard(0x00E7) }
    static var mute: Key { standard(0x007F) }
    static var volumeUp: Key { standard(0x0080) }
    static var volumeDown: Key { standard(0x0081) }
    static var keyboardVolumeUp: Key { standard(0x00A9) }
    static var keyboardVolumeDown: Key { standard(0x00AA) }
    static var nextTrack: Key { standard(0x00AB) }
    static var previousTrack: Key { standard(0x00AC) }
    static var playPause: Key { standard(0x00AE) }
    static var bootloader: Key { standard(0x7C00) }

    static var exclamation: Key { standard(0x021E) }
    static var at: Key { standard(0x021F) }
    static var hash: Key { standard(0x0220) }
    static var dollar: Key { standard(0x0221) }
    static var percent: Key { standard(0x0222) }
    static var caret: Key { standard(0x0223) }
    static var leftParenthesis: Key { standard(0x0226) }
    static var rightParenthesis: Key { standard(0x0227) }
    static var leftBrace: Key { standard(0x022F) }
    static var rightBrace: Key { standard(0x0230) }
    static var colon: Key { standard(0x0233) }
    static var plus: Key { standard(0x022E) }

    static var rgbToggle: Key { standard(0x7842) }
    static var rgbNext: Key { standard(0x7843) }
    static var rgbPrevious: Key { standard(0x7844) }
    static var rgbHueUp: Key { standard(0x7845) }
    static var rgbHueDown: Key { standard(0x7846) }
    static var rgbSaturationUp: Key { standard(0x7847) }
    static var rgbSaturationDown: Key { standard(0x7848) }
    static var rgbValueUp: Key { standard(0x7849) }
    static var rgbValueDown: Key { standard(0x784A) }
    static var rgbSpeedUp: Key { standard(0x784B) }
    static var rgbSpeedDown: Key { standard(0x784C) }

    /// Creates a function key in QMK's supported range.
    ///
    /// - Parameter number: A function-key number from 1 through 24.
    /// - Returns: The matching QMK function key.
    static func function(_ number: Int) -> Key {
        precondition((1...24).contains(number), "QMK function keys are limited to F1...F24.")
        let hidValue: UInt16 = switch number {
        case 1...12: UInt16(0x0039 + number)
        case 13...24: UInt16(0x005B + number)
        default: 0
        }
        return standard(hidValue)
    }

    /// Creates one standard QMK key action from its exact ABI value.
    fileprivate static func standard(_ value: UInt16) -> Key {
        Key(keycode: QMKKeycode(rawValue: value))
    }
}
