// Elora Rev2 Keymap in Swift DSL
// SPDX-License-Identifier: GPL-2.0-or-later

/// Elora keymap using SwiftUI-like DSL
/// Elora is essentially Kyria with an additional number row
public let eloraKeymap = Keymap {
    // MARK: - Default Layer (Colemak-DH)
    DefineLayer(.default) {
        // Number row (Elora only)
        RowFragments.defaultNumL
        RowFragments.defaultNumR

        // Row 1: Tab row
        RowFragments.defaultL1
        RowFragments.defaultR1

        // Row 2: Home row
        RowFragments.defaultL2
        RowFragments.defaultR2

        // Row 3: Bottom row + extra keys (L3 + extra left, extra right + R3)
        Row { .leftShift; .z; .x; .c; .d; .v; .leftAlt; .mouseButton1 }
        Row { .fkeys; .no; .k; .h; .comma; .dot; .slash; .enter }

        // Thumb row
        RowFragments.defaultThumbL
        RowFragments.defaultThumbR

        // Module row
        RowFragments.defaultModuleL
        RowFragments.defaultModuleR
    }

    // MARK: - QWERTY Layer (Gaming)
    DefineLayer(.qwerty) {
        RowFragments.qwertyNumL
        RowFragments.qwertyNumR

        RowFragments.qwertyL1
        RowFragments.qwertyR1
        RowFragments.qwertyL2
        RowFragments.qwertyR2

        Row { .leftShift; .z; .x; .c; .v; .b; .leftAlt; .mouseButton1 }
        Row { .fkeys; .no; .n; .m; .comma; .dot; .slash; .enter }

        RowFragments.qwertyThumbL
        RowFragments.qwertyThumbR
        RowFragments.qwertyModuleL
        RowFragments.qwertyModuleR
    }

    // MARK: - Lower Layer (Navigation)
    DefineLayer(.lower) {
        RowFragments.lowerNumL
        RowFragments.lowerNumR

        RowFragments.lowerL1
        RowFragments.lowerR1
        RowFragments.lowerL2
        RowFragments.lowerR2

        Row { ._______; ._______; ._______; ._______; ._______; ._______; ._______; ._______ }
        Row { ._______; ._______; ._______; ._______; ._______; ._______; ._______; ._______ }

        RowFragments.lowerThumbL
        RowFragments.lowerThumbR
        RowFragments.lowerModuleL
        RowFragments.lowerModuleR
    }

    // MARK: - Raise Layer (Symbols/Numbers)
    DefineLayer(.raise) {
        RowFragments.raiseNumL
        RowFragments.raiseNumR

        RowFragments.raiseL1
        RowFragments.raiseR1
        RowFragments.raiseL2
        RowFragments.raiseR2

        Row { ._______; .percent; .circumflex; .leftCurly; .rightCurly; ._______; ._______; ._______ }
        Row { ._______; ._______; ._0; ._1; ._2; ._3; .dot; .backslash }

        RowFragments.raiseThumbL
        RowFragments.raiseThumbR
        RowFragments.raiseModuleL
        RowFragments.raiseModuleR
    }

    // MARK: - Function Layer (F-keys, RGB, Boot)
    DefineLayer(.function) {
        RowFragments.funcNumL
        RowFragments.funcNumR

        RowFragments.funcL1
        RowFragments.funcR1
        RowFragments.funcL2
        RowFragments.funcR2

        Row { ._______; .f1; .f2; .f3; .f4; .f5; ._______; .toggleQwerty }
        Row { ._______; ._______; ._______; .rgbSatDown; .rgbHueDown; .rgbValDown; .rgbPrev; ._______ }

        RowFragments.funcThumbL
        RowFragments.funcThumbR
        RowFragments.funcModuleL
        RowFragments.funcModuleR
    }
}

/// Encoder map for Elora (same as Kyria)
public let eloraEncoderMap: [Layer: EncoderMap] = [
    .default: EncoderMap(actions: [
        Encoder(ccw: .volumeDown, cw: .volumeUp),
        Encoder(ccw: .volumeDown, cw: .volumeUp),
        Encoder(ccw: .volumeDown, cw: .volumeUp),
        Encoder(ccw: .volumeDown, cw: .volumeUp)
    ]),
    .qwerty: EncoderMap(actions: [
        Encoder(ccw: .volumeDown, cw: .volumeUp),
        Encoder(ccw: .volumeDown, cw: .volumeUp),
        Encoder(ccw: .volumeDown, cw: .volumeUp),
        Encoder(ccw: .volumeDown, cw: .volumeUp)
    ]),
    .lower: EncoderMap(actions: [
        Encoder(ccw: .mediaPrev, cw: .mediaNext),
        Encoder(ccw: .mediaPrev, cw: .mediaNext),
        Encoder(ccw: .mediaPrev, cw: .mediaNext),
        Encoder(ccw: .mediaPrev, cw: .mediaNext)
    ]),
    .raise: EncoderMap(actions: [
        Encoder(ccw: .volumeDown, cw: .volumeUp),
        Encoder(ccw: .volumeDown, cw: .volumeUp),
        Encoder(ccw: .volumeDown, cw: .volumeUp),
        Encoder(ccw: .volumeDown, cw: .volumeUp)
    ]),
    .function: EncoderMap(actions: [
        Encoder(ccw: .rgbPrev, cw: .rgbNext),
        Encoder(ccw: .rgbPrev, cw: .rgbNext),
        Encoder(ccw: .rgbPrev, cw: .rgbNext),
        Encoder(ccw: .rgbPrev, cw: .rgbNext)
    ])
]
