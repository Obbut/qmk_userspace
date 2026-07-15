import QMKKeymapKit

/// The five reusable typing and control layers shared by Kyria and Elora.
public struct SharedHalcyonLayers: KeymapComponent, Sendable {
    public typealias Domain = ObbutKeymapDomain

    public let keymapElements: [KeymapElement<ObbutKeymapDomain>]

    /// Includes a physical number row for the Elora layout.
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

    fileprivate static func transparent(count: Int) -> [Key<Domain>] {
        Array(repeating: .transparent, count: count)
    }
}

fileprivate extension SharedHalcyonLayers {
    static var numberRow: [Key<Domain>] {
        [.grave, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .zero, .minus]
    }

    static var colemakRowOne: [Key<Domain>] {
        [.tab, .q, .w, .f, .p, .b, .j, .l, .u, .y, .semicolon, .backspace]
    }

    static var colemakRowTwo: [Key<Domain>] {
        [.escape, .a, .r, .s, .t, .g, .m, .n, .e, .i, .o, .quote]
    }

    static var colemakBottomWithModules: [Key<Domain>] {
        [
            .leftShift, .z, .x, .c, .d, .v,
            .leftOption, ObbutKey.pointerLeftClick,
            .momentary(ObbutLayer.function), .no,
            .k, .h, .comma, .period, .slash, .return,
        ]
    }

    static var baseThumbs: [Key<Domain>] {
        [
            ObbutKey.screenshot, .leftControl, .leftCommand, ObbutKey.aerospace, .space,
            .no, .space, .momentary(ObbutLayer.raise), .momentary(ObbutLayer.lower), .no,
        ]
    }

    static var baseModules: [Key<Domain>] {
        [.no, .no, .no, .no, .no, .mute, .no, .no, .no, .no]
    }

    static var qwertyRowOne: [Key<Domain>] {
        [
            .tab, .q, .w.style(.gaming), .e, .r, .t,
            .y, .u, .i, .o, .p, .backspace,
        ]
    }

    static var qwertyRowTwo: [Key<Domain>] {
        [
            .escape, .a.style(.gaming), .s.style(.gaming), .d.style(.gaming), .f, .g,
            .h, .j, .k, .l, .semicolon, .quote,
        ]
    }

    static var qwertyBottomWithModules: [Key<Domain>] {
        [
            .leftShift, .z, .x, .c, .v, .b,
            .leftOption.style(.gaming), ObbutKey.pointerLeftClick,
            .momentary(ObbutLayer.function), .no,
            .n, .m, .comma, .period, .slash, .return,
        ]
    }

    static var qwertyThumbs: [Key<Domain>] {
        [
            .leftControl.style(.gaming), .leftOption.style(.gaming),
            .space.style(.gaming), .space.style(.gaming), .space.style(.gaming),
            .no, .space, .momentary(ObbutLayer.raise), .momentary(ObbutLayer.lower), .no,
        ]
    }
}

fileprivate extension SharedHalcyonLayers {
    static var lowerRowOne: [Key<Domain>] {
        transparent(count: 10)
            + [.delete.style(.destructive), .backspace.style(.destructive)]
    }

    static var lowerRowTwo: [Key<Domain>] {
        transparent(count: 6)
            + [
                .left.style(.navigation), .down.style(.navigation),
                .up.style(.navigation), .right.style(.navigation),
            ]
            + transparent(count: 2)
    }

    static var lowerBottomWithModules: [Key<Domain>] {
        transparent(count: 16)
    }

    static var lowerModules: [Key<Domain>] {
        transparent(count: 5) + [.playPause] + transparent(count: 4)
    }

    static var raiseRowOne: [Key<Domain>] {
        [
            .grave.style(.symbol), .exclamation.style(.symbol), .at.style(.symbol),
            .leftBracket.style(.symbol), .rightBracket.style(.symbol), .transparent,
            .colon.style(.symbol), .seven.style(.number), .eight.style(.number),
            .nine.style(.number), .minus.style(.symbol), .transparent,
        ]
    }

    static var raiseRowTwo: [Key<Domain>] {
        [
            .transparent, .hash.style(.symbol), .dollar.style(.symbol),
            .leftParenthesis.style(.symbol), .rightParenthesis.style(.symbol),
            .colon.style(.symbol), .transparent,
            .four.style(.number), .five.style(.number), .six.style(.number),
            .plus.style(.symbol), .equal.style(.symbol),
        ]
    }

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

fileprivate extension SharedHalcyonLayers {
    static var functionRowOne: [Key<Domain>] {
        [.transparent]
            + (11...15).map { Key<Domain>.function($0).style(.function) }
            + transparent(count: 6)
    }

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
