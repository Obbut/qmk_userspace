import QMKKeymapKit

/// The five reusable typing and control layers shared by Kyria and Elora.
public struct SharedHalcyonLayers: KeymapComponent, Sendable {
    /// The keymap domain selected by this component.
    public typealias Domain = ObbutKeymapDomain

    /// The layers contributed by this component.
    public let keymapElements: [KeymapElement<ObbutKeymapDomain>]

    /// Creates the shared layers for one Halcyon layout shape.
    ///
    /// - Parameter layout: Whether a physical number row is present.
    public init(layout: HalcyonLayoutKind) {
        keymapElements = [
            .layer(Self.baseLayer(layout: layout)),
            .layer(Self.qwertyLayer(layout: layout)),
            .layer(Self.lowerLayer(layout: layout)),
            .layer(Self.raiseLayer(layout: layout)),
            .layer(Self.functionLayer(layout: layout)),
        ]
    }

    /// Creates the Colemak-DH base layer.
    fileprivate static func baseLayer(layout: HalcyonLayoutKind) -> Layer<Domain> {
        Layer(ObbutLayer.base, name: "Default") {
            if layout == .elora { Row(keys: numberRow) }
            Row(keys: colemakRowOne)
            Row(keys: colemakRowTwo)
            Row(keys: colemakBottomWithModules)
            Row(keys: baseThumbs)
            Row(keys: baseModules)
        }
    }

    /// Creates the QWERTY gaming layer.
    fileprivate static func qwertyLayer(layout: HalcyonLayoutKind) -> Layer<Domain> {
        Layer(ObbutLayer.qwerty, name: "QWERTY") {
            if layout == .elora { Row(keys: numberRow) }
            Row(keys: qwertyRowOne)
            Row(keys: qwertyRowTwo)
            Row(keys: qwertyBottomWithModules)
            Row(keys: qwertyThumbs)
            Row(keys: baseModules)
        }
    }

    /// Creates the navigation layer.
    fileprivate static func lowerLayer(layout: HalcyonLayoutKind) -> Layer<Domain> {
        Layer(ObbutLayer.lower, name: "Lower", showsHUD: true) {
            if layout == .elora { Row(keys: transparent(count: 12)) }
            Row(keys: lowerRowOne)
            Row(keys: lowerRowTwo)
            Row(keys: lowerBottomWithModules)
            Row(keys: transparent(count: 10))
            Row(keys: lowerModules)
        }
    }

    /// Creates the number and symbol layer.
    fileprivate static func raiseLayer(layout: HalcyonLayoutKind) -> Layer<Domain> {
        Layer(ObbutLayer.raise, name: "Raise", showsHUD: true) {
            if layout == .elora { Row(keys: transparent(count: 12)) }
            Row(keys: raiseRowOne)
            Row(keys: raiseRowTwo)
            Row(keys: raiseBottomWithModules)
            Row(keys: transparent(count: 10))
            Row(keys: transparent(count: 10))
        }
    }

    /// Creates the function and firmware-control layer.
    fileprivate static func functionLayer(layout: HalcyonLayoutKind) -> Layer<Domain> {
        Layer(ObbutLayer.function, name: "Function", showsHUD: true) {
            if layout == .elora { Row(keys: transparent(count: 12)) }
            Row(keys: functionRowOne)
            Row(keys: functionRowTwo)
            Row(keys: functionBottomWithModules)
            Row(keys: transparent(count: 10))
            Row(keys: transparent(count: 10))
        }
    }

    /// Creates a repeated transparent-key sequence.
    fileprivate static func transparent(count: Int) -> [Key<Domain>] {
        Array(repeating: .transparent, count: count)
    }
}

/// Shared base and gaming layer rows.
fileprivate extension SharedHalcyonLayers {
    /// The optional physical number row.
    static var numberRow: [Key<Domain>] {
        [.grave, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .zero, .minus]
    }

    /// Colemak-DH row one.
    static var colemakRowOne: [Key<Domain>] {
        [.tab, .q, .w, .f, .p, .b, .j, .l, .u, .y, .semicolon, .backspace]
    }

    /// Colemak-DH row two.
    static var colemakRowTwo: [Key<Domain>] {
        [.escape, .a, .r, .s, .t, .g, .m, .n, .e, .i, .o, .quote]
    }

    /// Colemak-DH bottom row with the two inner module keys on each side.
    static var colemakBottomWithModules: [Key<Domain>] {
        [
            .leftShift, .z, .x, .c, .d, .v,
            .leftOption, ObbutKey.pointerLeftClick,
            .momentary(ObbutLayer.function), .no,
            .k, .h, .comma, .period, .slash, .return,
        ]
    }

    /// Base-layer thumb keys.
    static var baseThumbs: [Key<Domain>] {
        [
            ObbutKey.screenshot, .leftControl, .leftCommand, ObbutKey.aerospace, .space,
            .no, .space, .momentary(ObbutLayer.raise), .momentary(ObbutLayer.lower), .no,
        ]
    }

    /// Module-row keys shared by both typing layers.
    static var baseModules: [Key<Domain>] {
        [.no, .no, .no, .no, .no, .mute, .no, .no, .no, .no]
    }

    /// QWERTY row one.
    static var qwertyRowOne: [Key<Domain>] {
        [
            .tab, .q, .w.style(.gaming), .e, .r, .t,
            .y, .u, .i, .o, .p, .backspace,
        ]
    }

    /// QWERTY row two.
    static var qwertyRowTwo: [Key<Domain>] {
        [
            .escape, .a.style(.gaming), .s.style(.gaming), .d.style(.gaming), .f, .g,
            .h, .j, .k, .l, .semicolon, .quote,
        ]
    }

    /// QWERTY bottom row with module keys.
    static var qwertyBottomWithModules: [Key<Domain>] {
        [
            .leftShift, .z, .x, .c, .v, .b,
            .leftOption.style(.gaming), ObbutKey.pointerLeftClick,
            .momentary(ObbutLayer.function), .no,
            .n, .m, .comma, .period, .slash, .return,
        ]
    }

    /// Gaming-optimized thumb keys.
    static var qwertyThumbs: [Key<Domain>] {
        [
            .leftControl.style(.gaming), .leftOption.style(.gaming),
            .space.style(.gaming), .space.style(.gaming), .space.style(.gaming),
            .no, .space, .momentary(ObbutLayer.raise), .momentary(ObbutLayer.lower), .no,
        ]
    }
}

/// Shared navigation and symbol layer rows.
fileprivate extension SharedHalcyonLayers {
    /// Lower row one.
    static var lowerRowOne: [Key<Domain>] {
        transparent(count: 10)
            + [.delete.style(.destructive), .backspace.style(.destructive)]
    }

    /// Lower row two.
    static var lowerRowTwo: [Key<Domain>] {
        transparent(count: 6)
            + [
                .left.style(.navigation), .down.style(.navigation),
                .up.style(.navigation), .right.style(.navigation),
            ]
            + transparent(count: 2)
    }

    /// Lower bottom row with transparent module positions.
    static var lowerBottomWithModules: [Key<Domain>] {
        transparent(count: 16)
    }

    /// Lower module row containing media playback on encoder press.
    static var lowerModules: [Key<Domain>] {
        transparent(count: 5) + [.playPause] + transparent(count: 4)
    }

    /// Raise row one.
    static var raiseRowOne: [Key<Domain>] {
        [
            .grave.style(.symbol), .exclamation.style(.symbol), .at.style(.symbol),
            .leftBracket.style(.symbol), .rightBracket.style(.symbol), .transparent,
            .colon.style(.symbol), .seven.style(.number), .eight.style(.number),
            .nine.style(.number), .minus.style(.symbol), .transparent,
        ]
    }

    /// Raise row two.
    static var raiseRowTwo: [Key<Domain>] {
        [
            .transparent, .hash.style(.symbol), .dollar.style(.symbol),
            .leftParenthesis.style(.symbol), .rightParenthesis.style(.symbol),
            .colon.style(.symbol), .transparent,
            .four.style(.number), .five.style(.number), .six.style(.number),
            .plus.style(.symbol), .equal.style(.symbol),
        ]
    }

    /// Raise bottom row with module positions.
    static var raiseBottomWithModules: [Key<Domain>] {
        [
            .transparent, .percent.style(.symbol), .caret.style(.symbol),
            .leftBrace.style(.symbol), .rightBrace.style(.symbol), .transparent,
            .transparent, .transparent, .transparent, .transparent,
            .zero.style(.number), .one.style(.number), .two.style(.number),
            .three.style(.number), .period.style(.symbol), .backslash.style(.symbol),
        ]
    }
}

/// Shared function-layer rows.
fileprivate extension SharedHalcyonLayers {
    /// Function row one containing F11 through F15.
    static var functionRowOne: [Key<Domain>] {
        [.transparent]
            + (11...15).map { Key<Domain>.function($0).style(.function) }
            + transparent(count: 6)
    }

    /// Function row two containing bootloader, F keys, and RGB controls.
    static var functionRowTwo: [Key<Domain>] {
        [
            .bootloader.style(.bootloader),
            .function(6).style(.function), .function(7).style(.function),
            .function(8).style(.function), .function(9).style(.function),
            .function(10).style(.function),
            .qmk("RM_TOGG", legend: "RGB", style: .increase),
            .qmk("RM_SATU", legend: "Sat+", style: .increase),
            .qmk("RM_HUEU", legend: "Hue+", style: .increase),
            .qmk("RM_VALU", legend: "Brt+", style: .increase),
            .qmk("RM_NEXT", legend: "Next", style: .increase),
            .bootloader.style(.bootloader),
        ]
    }

    /// Function bottom row containing F1 through F5 and RGB decreases.
    static var functionBottomWithModules: [Key<Domain>] {
        [.transparent]
            + (1...5).map { Key<Domain>.function($0).style(.function) }
            + [.transparent, .toggle(ObbutLayer.qwerty).style(.gaming)]
            + transparent(count: 2)
            + [
                .transparent,
                .qmk("RM_SATD", legend: "Sat−", style: .decrease),
                .qmk("RM_HUED", legend: "Hue−", style: .decrease),
                .qmk("RM_VALD", legend: "Brt−", style: .decrease),
                .qmk("RM_PREV", legend: "Previous", style: .decrease),
                .transparent,
            ]
    }
}
