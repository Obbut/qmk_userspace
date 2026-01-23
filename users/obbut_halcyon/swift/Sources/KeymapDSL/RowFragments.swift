// Shared row definitions for Kyria and Elora keymaps
// These mirror the C macros in obbut_halcyon.h
// SPDX-License-Identifier: GPL-2.0-or-later

/// Namespace for reusable row definitions (like the C macros DEFAULT_L1, etc.)
public enum RowFragments {

    // MARK: - Default Layer (Colemak-DH)

    /// Alpha row 1 left - Tab row
    public static var defaultL1: [Keycode] {
        Row { .tab; .q; .w; .f; .p; .b }
    }

    /// Alpha row 1 right
    public static var defaultR1: [Keycode] {
        Row { .j; .l; .u; .y; .semicolon; .backspace }
    }

    /// Alpha row 2 left - Home row
    public static var defaultL2: [Keycode] {
        Row { .escape; .a; .r; .s; .t; .g }
    }

    /// Alpha row 2 right
    public static var defaultR2: [Keycode] {
        Row { .m; .n; .e; .i; .o; .quote }
    }

    /// Alpha row 3 left - Bottom row
    public static var defaultL3: [Keycode] {
        Row { .leftShift; .z; .x; .c; .d; .v }
    }

    /// Alpha row 3 right
    public static var defaultR3: [Keycode] {
        Row { .k; .h; .comma; .dot; .slash; .enter }
    }

    /// Thumb row left (5 keys)
    public static var defaultThumbL: [Keycode] {
        Row { .screenshot; .leftControl; .leftGui; .aerospace; .space }
    }

    /// Thumb row right (5 keys)
    public static var defaultThumbR: [Keycode] {
        Row { .no; .space; .raise; .lower; .no }
    }

    /// Module row left (5 keys) - for encoder/trackpad modules
    public static var defaultModuleL: [Keycode] {
        Row { .no; .no; .no; .no; .no }
    }

    /// Module row right (5 keys)
    public static var defaultModuleR: [Keycode] {
        Row { .no; .no; .no; .no; .no }
    }

    /// Number row left (Elora only)
    public static var defaultNumL: [Keycode] {
        Row { .grave; ._1; ._2; ._3; ._4; ._5 }
    }

    /// Number row right (Elora only)
    public static var defaultNumR: [Keycode] {
        Row { ._6; ._7; ._8; ._9; ._0; .minus }
    }

    // MARK: - QWERTY Layer (Gaming)

    public static var qwertyL1: [Keycode] {
        Row { .tab; .q; .w; .e; .r; .t }
    }

    public static var qwertyR1: [Keycode] {
        Row { .y; .u; .i; .o; .p; .backspace }
    }

    public static var qwertyL2: [Keycode] {
        Row { .escape; .a; .s; .d; .f; .g }
    }

    public static var qwertyR2: [Keycode] {
        Row { .h; .j; .k; .l; .semicolon; .quote }
    }

    public static var qwertyL3: [Keycode] {
        Row { .leftShift; .z; .x; .c; .v; .b }
    }

    public static var qwertyR3: [Keycode] {
        Row { .n; .m; .comma; .dot; .slash; .enter }
    }

    /// Simplified left thumb for gaming (CTRL, ALT, then spaces)
    public static var qwertyThumbL: [Keycode] {
        Row { .leftControl; .leftAlt; .space; .space; .space }
    }

    public static var qwertyThumbR: [Keycode] {
        Row { .no; .space; .raise; .lower; .no }
    }

    public static var qwertyModuleL: [Keycode] {
        Row { .no; .no; .no; .no; .no }
    }

    public static var qwertyModuleR: [Keycode] {
        Row { .no; .no; .no; .no; .no }
    }

    public static var qwertyNumL: [Keycode] {
        Row { .grave; ._1; ._2; ._3; ._4; ._5 }
    }

    public static var qwertyNumR: [Keycode] {
        Row { ._6; ._7; ._8; ._9; ._0; .minus }
    }

    // MARK: - Lower Layer (Navigation)

    public static var lowerL1: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______; ._______ }
    }

    public static var lowerR1: [Keycode] {
        Row { ._______; ._______; ._______; ._______; .delete; .backspace }
    }

    public static var lowerL2: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______; ._______ }
    }

    public static var lowerR2: [Keycode] {
        Row { .left; .down; .up; .right; ._______; ._______ }
    }

    public static var lowerL3: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______; ._______ }
    }

    public static var lowerR3: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______; ._______ }
    }

    public static var lowerThumbL: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______ }
    }

    public static var lowerThumbR: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______ }
    }

    public static var lowerModuleL: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______ }
    }

    public static var lowerModuleR: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______ }
    }

    public static var lowerNumL: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______; ._______ }
    }

    public static var lowerNumR: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______; ._______ }
    }

    // MARK: - Raise Layer (Symbols/Numbers)

    public static var raiseL1: [Keycode] {
        Row { .grave; .exclaim; .at; .leftBracket; .rightBracket; ._______ }
    }

    public static var raiseR1: [Keycode] {
        Row { .colon; ._7; ._8; ._9; .minus; ._______ }
    }

    public static var raiseL2: [Keycode] {
        Row { ._______; .hash; .dollar; .leftParen; .rightParen; .colon }
    }

    public static var raiseR2: [Keycode] {
        Row { ._______; ._4; ._5; ._6; .plus; .equal }
    }

    public static var raiseL3: [Keycode] {
        Row { ._______; .percent; .circumflex; .leftCurly; .rightCurly; ._______ }
    }

    public static var raiseR3: [Keycode] {
        Row { ._0; ._1; ._2; ._3; .dot; .backslash }
    }

    public static var raiseThumbL: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______ }
    }

    public static var raiseThumbR: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______ }
    }

    public static var raiseModuleL: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______ }
    }

    public static var raiseModuleR: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______ }
    }

    public static var raiseNumL: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______; ._______ }
    }

    public static var raiseNumR: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______; ._______ }
    }

    // MARK: - Function Layer (F-keys, RGB, Boot)

    public static var funcL1: [Keycode] {
        Row { ._______; .f11; .f12; .f13; .f14; .f15 }
    }

    public static var funcR1: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______; ._______ }
    }

    public static var funcL2: [Keycode] {
        Row { .bootloader; .f6; .f7; .f8; .f9; .f10 }
    }

    public static var funcR2: [Keycode] {
        Row { .rgbToggle; .rgbSatUp; .rgbHueUp; .rgbValUp; .rgbNext; .bootloader }
    }

    public static var funcL3: [Keycode] {
        Row { ._______; .f1; .f2; .f3; .f4; .f5 }
    }

    public static var funcR3: [Keycode] {
        Row { ._______; .rgbSatDown; .rgbHueDown; .rgbValDown; .rgbPrev; ._______ }
    }

    public static var funcThumbL: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______ }
    }

    public static var funcThumbR: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______ }
    }

    public static var funcModuleL: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______ }
    }

    public static var funcModuleR: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______ }
    }

    public static var funcNumL: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______; ._______ }
    }

    public static var funcNumR: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______; ._______ }
    }

    // MARK: - Transparent Rows (Helpers)

    public static var transparentRow6: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______; ._______ }
    }

    public static var transparentRow5: [Keycode] {
        Row { ._______; ._______; ._______; ._______; ._______ }
    }
}
