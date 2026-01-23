// Type-safe Keycode wrapper for QMK keycodes
// SPDX-License-Identifier: GPL-2.0-or-later

/// Type-safe keycode wrapper matching QMK's uint16_t keycodes
public struct Keycode: Equatable, Sendable {
    public let rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
}

// MARK: - Special Keycodes

extension Keycode {
    /// Transparent key - passes through to lower layer
    public static let transparent = Keycode(rawValue: 0x0001)
    /// Alias for transparent (matches QMK's _______ macro)
    public static let _______ = transparent

    /// No operation - blocks key
    public static let no = Keycode(rawValue: 0x0000)
    /// Alias for no operation
    public static let XXXXXXX = no
}

// MARK: - Letter Keys (USB HID codes)

extension Keycode {
    public static let a = Keycode(rawValue: 0x04)
    public static let b = Keycode(rawValue: 0x05)
    public static let c = Keycode(rawValue: 0x06)
    public static let d = Keycode(rawValue: 0x07)
    public static let e = Keycode(rawValue: 0x08)
    public static let f = Keycode(rawValue: 0x09)
    public static let g = Keycode(rawValue: 0x0A)
    public static let h = Keycode(rawValue: 0x0B)
    public static let i = Keycode(rawValue: 0x0C)
    public static let j = Keycode(rawValue: 0x0D)
    public static let k = Keycode(rawValue: 0x0E)
    public static let l = Keycode(rawValue: 0x0F)
    public static let m = Keycode(rawValue: 0x10)
    public static let n = Keycode(rawValue: 0x11)
    public static let o = Keycode(rawValue: 0x12)
    public static let p = Keycode(rawValue: 0x13)
    public static let q = Keycode(rawValue: 0x14)
    public static let r = Keycode(rawValue: 0x15)
    public static let s = Keycode(rawValue: 0x16)
    public static let t = Keycode(rawValue: 0x17)
    public static let u = Keycode(rawValue: 0x18)
    public static let v = Keycode(rawValue: 0x19)
    public static let w = Keycode(rawValue: 0x1A)
    public static let x = Keycode(rawValue: 0x1B)
    public static let y = Keycode(rawValue: 0x1C)
    public static let z = Keycode(rawValue: 0x1D)
}

// MARK: - Number Keys

extension Keycode {
    public static let _1 = Keycode(rawValue: 0x1E)
    public static let _2 = Keycode(rawValue: 0x1F)
    public static let _3 = Keycode(rawValue: 0x20)
    public static let _4 = Keycode(rawValue: 0x21)
    public static let _5 = Keycode(rawValue: 0x22)
    public static let _6 = Keycode(rawValue: 0x23)
    public static let _7 = Keycode(rawValue: 0x24)
    public static let _8 = Keycode(rawValue: 0x25)
    public static let _9 = Keycode(rawValue: 0x26)
    public static let _0 = Keycode(rawValue: 0x27)
}

// MARK: - Control Keys

extension Keycode {
    public static let enter = Keycode(rawValue: 0x28)
    public static let escape = Keycode(rawValue: 0x29)
    public static let backspace = Keycode(rawValue: 0x2A)
    public static let tab = Keycode(rawValue: 0x2B)
    public static let space = Keycode(rawValue: 0x2C)
}

// MARK: - Punctuation and Symbols

extension Keycode {
    public static let minus = Keycode(rawValue: 0x2D)      // - and _
    public static let equal = Keycode(rawValue: 0x2E)      // = and +
    public static let leftBracket = Keycode(rawValue: 0x2F)  // [ and {
    public static let rightBracket = Keycode(rawValue: 0x30) // ] and }
    public static let backslash = Keycode(rawValue: 0x31)  // \ and |
    public static let semicolon = Keycode(rawValue: 0x33)  // ; and :
    public static let quote = Keycode(rawValue: 0x34)      // ' and "
    public static let grave = Keycode(rawValue: 0x35)      // ` and ~
    public static let comma = Keycode(rawValue: 0x36)      // , and <
    public static let dot = Keycode(rawValue: 0x37)        // . and >
    public static let slash = Keycode(rawValue: 0x38)      // / and ?
}

// MARK: - Function Keys

extension Keycode {
    public static let f1 = Keycode(rawValue: 0x3A)
    public static let f2 = Keycode(rawValue: 0x3B)
    public static let f3 = Keycode(rawValue: 0x3C)
    public static let f4 = Keycode(rawValue: 0x3D)
    public static let f5 = Keycode(rawValue: 0x3E)
    public static let f6 = Keycode(rawValue: 0x3F)
    public static let f7 = Keycode(rawValue: 0x40)
    public static let f8 = Keycode(rawValue: 0x41)
    public static let f9 = Keycode(rawValue: 0x42)
    public static let f10 = Keycode(rawValue: 0x43)
    public static let f11 = Keycode(rawValue: 0x44)
    public static let f12 = Keycode(rawValue: 0x45)
    public static let f13 = Keycode(rawValue: 0x68)
    public static let f14 = Keycode(rawValue: 0x69)
    public static let f15 = Keycode(rawValue: 0x6A)
}

// MARK: - Navigation Keys

extension Keycode {
    public static let printScreen = Keycode(rawValue: 0x46)
    public static let scrollLock = Keycode(rawValue: 0x47)
    public static let pause = Keycode(rawValue: 0x48)
    public static let insert = Keycode(rawValue: 0x49)
    public static let home = Keycode(rawValue: 0x4A)
    public static let pageUp = Keycode(rawValue: 0x4B)
    public static let delete = Keycode(rawValue: 0x4C)
    public static let end = Keycode(rawValue: 0x4D)
    public static let pageDown = Keycode(rawValue: 0x4E)
    public static let right = Keycode(rawValue: 0x4F)
    public static let left = Keycode(rawValue: 0x50)
    public static let down = Keycode(rawValue: 0x51)
    public static let up = Keycode(rawValue: 0x52)
}

// MARK: - Modifier Keys

extension Keycode {
    public static let leftControl = Keycode(rawValue: 0xE0)
    public static let leftShift = Keycode(rawValue: 0xE1)
    public static let leftAlt = Keycode(rawValue: 0xE2)
    public static let leftGui = Keycode(rawValue: 0xE3)  // Command on macOS, Windows key
    public static let rightControl = Keycode(rawValue: 0xE4)
    public static let rightShift = Keycode(rawValue: 0xE5)
    public static let rightAlt = Keycode(rawValue: 0xE6)
    public static let rightGui = Keycode(rawValue: 0xE7)

    // Aliases
    public static let lctl = leftControl
    public static let lsft = leftShift
    public static let lalt = leftAlt
    public static let lgui = leftGui
    public static let lcmd = leftGui  // macOS alias
    public static let rctl = rightControl
    public static let rsft = rightShift
    public static let ralt = rightAlt
    public static let rgui = rightGui
}

// MARK: - Media Keys

extension Keycode {
    public static let volumeUp = Keycode(rawValue: 0x80)
    public static let volumeDown = Keycode(rawValue: 0x81)
    public static let mute = Keycode(rawValue: 0x7F)
    public static let mediaNext = Keycode(rawValue: 0xB5)
    public static let mediaPrev = Keycode(rawValue: 0xB6)
    public static let mediaStop = Keycode(rawValue: 0xB7)
    public static let mediaPlayPause = Keycode(rawValue: 0xCD)
}

// MARK: - Shifted Symbols (QMK S() macro)
// These are shifted versions of other keys

extension Keycode {
    // Shifted number row
    public static let exclaim = Keycode(rawValue: 0x021E)     // ! (Shift+1)
    public static let at = Keycode(rawValue: 0x021F)          // @ (Shift+2)
    public static let hash = Keycode(rawValue: 0x0220)        // # (Shift+3)
    public static let dollar = Keycode(rawValue: 0x0221)      // $ (Shift+4)
    public static let percent = Keycode(rawValue: 0x0222)     // % (Shift+5)
    public static let circumflex = Keycode(rawValue: 0x0223)  // ^ (Shift+6)
    public static let ampersand = Keycode(rawValue: 0x0224)   // & (Shift+7)
    public static let asterisk = Keycode(rawValue: 0x0225)    // * (Shift+8)
    public static let leftParen = Keycode(rawValue: 0x0226)   // ( (Shift+9)
    public static let rightParen = Keycode(rawValue: 0x0227)  // ) (Shift+0)

    // Shifted punctuation
    public static let underscore = Keycode(rawValue: 0x022D)  // _ (Shift+-)
    public static let plus = Keycode(rawValue: 0x022E)        // + (Shift+=)
    public static let leftCurly = Keycode(rawValue: 0x022F)   // { (Shift+[)
    public static let rightCurly = Keycode(rawValue: 0x0230)  // } (Shift+])
    public static let pipe = Keycode(rawValue: 0x0231)        // | (Shift+\)
    public static let colon = Keycode(rawValue: 0x0233)       // : (Shift+;)
    public static let doubleQuote = Keycode(rawValue: 0x0234) // " (Shift+')
    public static let tilde = Keycode(rawValue: 0x0235)       // ~ (Shift+`)
    public static let lessThan = Keycode(rawValue: 0x0236)    // < (Shift+,)
    public static let greaterThan = Keycode(rawValue: 0x0237) // > (Shift+.)
    public static let question = Keycode(rawValue: 0x0238)    // ? (Shift+/)
}

// MARK: - Mouse Keys

extension Keycode {
    public static let mouseButton1 = Keycode(rawValue: 0x00CD)
    public static let mouseButton2 = Keycode(rawValue: 0x00CE)
    public static let mouseButton3 = Keycode(rawValue: 0x00CF)
}

// MARK: - RGB Matrix Control (QMK RM_* keycodes)
// These values match QMK's RGB Matrix keycodes

extension Keycode {
    public static let rgbToggle = Keycode(rawValue: 0x5CC0)   // RM_TOGG
    public static let rgbNext = Keycode(rawValue: 0x5CC1)     // RM_NEXT
    public static let rgbPrev = Keycode(rawValue: 0x5CC2)     // RM_PREV
    public static let rgbHueUp = Keycode(rawValue: 0x5CC3)    // RM_HUEU
    public static let rgbHueDown = Keycode(rawValue: 0x5CC4)  // RM_HUED
    public static let rgbSatUp = Keycode(rawValue: 0x5CC5)    // RM_SATU
    public static let rgbSatDown = Keycode(rawValue: 0x5CC6)  // RM_SATD
    public static let rgbValUp = Keycode(rawValue: 0x5CC7)    // RM_VALU
    public static let rgbValDown = Keycode(rawValue: 0x5CC8)  // RM_VALD
}

// MARK: - System Keycodes

extension Keycode {
    public static let bootloader = Keycode(rawValue: 0x7C00)  // QK_BOOT
}

// MARK: - Layer Control

extension Keycode {
    /// Momentary layer activation (MO) - hold to activate layer
    public static func momentary(_ layer: Layer) -> Keycode {
        // QMK: MO(layer) = 0x5100 | layer
        Keycode(rawValue: 0x5100 | UInt16(layer.rawValue))
    }

    /// Toggle layer (TG) - toggle layer on/off
    public static func toggle(_ layer: Layer) -> Keycode {
        // QMK: TG(layer) = 0x5300 | layer
        Keycode(rawValue: 0x5300 | UInt16(layer.rawValue))
    }

    /// Layer tap (LT) - tap for keycode, hold for layer
    public static func layerTap(_ layer: Layer, _ keycode: Keycode) -> Keycode {
        // QMK: LT(layer, kc) = 0x4000 | (layer << 8) | kc
        Keycode(rawValue: 0x4000 | (UInt16(layer.rawValue) << 8) | (keycode.rawValue & 0xFF))
    }

    /// One-shot layer (OSL) - activate layer for one keypress
    public static func oneShot(_ layer: Layer) -> Keycode {
        // QMK: OSL(layer) = 0x5400 | layer
        Keycode(rawValue: 0x5400 | UInt16(layer.rawValue))
    }
}

// MARK: - Modifier Combinations

extension Keycode {
    /// Apply left Control modifier
    public func withControl() -> Keycode {
        Keycode(rawValue: rawValue | (0x01 << 8))
    }

    /// Apply left Shift modifier
    public func withShift() -> Keycode {
        Keycode(rawValue: rawValue | (0x02 << 8))
    }

    /// Apply left Alt/Option modifier
    public func withAlt() -> Keycode {
        Keycode(rawValue: rawValue | (0x04 << 8))
    }

    /// Apply left GUI/Command modifier
    public func withGui() -> Keycode {
        Keycode(rawValue: rawValue | (0x08 << 8))
    }

    /// Convenience for LCTL(kc)
    public static func lctl(_ kc: Keycode) -> Keycode {
        kc.withControl()
    }

    /// Convenience for LGUI(kc)
    public static func lgui(_ kc: Keycode) -> Keycode {
        kc.withGui()
    }

    /// Convenience for LSFT(kc)
    public static func lsft(_ kc: Keycode) -> Keycode {
        kc.withShift()
    }

    /// Convenience for LALT(kc)
    public static func lalt(_ kc: Keycode) -> Keycode {
        kc.withAlt()
    }
}

// MARK: - Convenience Layer Keycodes

extension Keycode {
    /// Lower layer momentary (MO(_LOWER))
    public static let lower = Keycode.momentary(.lower)

    /// Raise layer momentary (MO(_RAISE))
    public static let raise = Keycode.momentary(.raise)

    /// Function layer momentary (MO(_FUNCTION))
    public static let fkeys = Keycode.momentary(.function)

    /// Toggle QWERTY layer (TG(_QWERTY))
    public static let toggleQwerty = Keycode.toggle(.qwerty)
}

// MARK: - Custom Keycodes

extension Keycode {
    /// Screenshot key - sends Cmd+Ctrl+Shift+4 on macOS, Print Screen on Windows
    /// This is handled specially in swift_process_record
    public static let screenshot = Keycode(rawValue: 0x7E40)

    /// Aerospace window manager key - sends Cmd+Ctrl+Option
    public static let aerospace = Keycode(rawValue: 0x7E41)
}
