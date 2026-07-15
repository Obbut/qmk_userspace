import QMKKeymapKit

/// The complete reusable Planck layer set, kept in the shared Obbut module.
public struct SharedPlanckLayers: KeymapComponent, Sendable {
    /// The keymap domain selected by this component.
    public typealias Domain = ObbutKeymapDomain

    /// The five Planck layers.
    public let keymapElements: [KeymapElement<Domain>]

    /// Creates the complete Planck layer set.
    public init() {
        keymapElements = [
            .layer(Self.baseLayer),
            .layer(Self.qwertyLayer),
            .layer(Self.lowerLayer),
            .layer(Self.raiseLayer),
            .layer(Self.functionLayer),
        ]
    }

    /// The Colemak-DH base layer.
    fileprivate static var baseLayer: Layer<Domain> {
        Layer(ObbutLayer.base, name: "Default") {
            Row(.tab, .q, .w, .f, .p, .b, .j, .l, .u, .y, .semicolon, .backspace)
            Row(.escape, .a, .r, .s, .t, .g, .m, .n, .e, .i, .o, .quote)
            Row(.leftShift, .z, .x, .c, .d, .v, .k, .h, .comma, .period, .slash, .return)
            Row(
                ObbutKey.screenshot, .leftControl, .leftOption, ObbutKey.aerospace,
                .leftCommand, .space,
                .qmk("TL_UPPR", legend: "Raise"), .qmk("TL_LOWR", legend: "Lower"),
                .momentary(ObbutLayer.function), .rightOption, .delete
            )
        }
    }

    /// The QWERTY gaming layer.
    fileprivate static var qwertyLayer: Layer<Domain> {
        Layer(ObbutLayer.qwerty, name: "QWERTY") {
            Row(.tab, .q, .w.style(.gaming), .e, .r, .t, .y, .u, .i, .o, .p, .backspace)
            Row(
                .escape, .a.style(.gaming), .s.style(.gaming), .d.style(.gaming),
                .f, .g, .h, .j, .k, .l, .semicolon, .quote
            )
            Row(.leftShift, .z, .x, .c, .v, .b, .n, .m, .comma, .period, .slash, .return)
            Row(
                .leftControl.style(.gaming), .leftOption.style(.gaming),
                .space.style(.gaming), .space.style(.gaming), .space.style(.gaming),
                .space.style(.gaming), .qmk("TL_UPPR", legend: "Raise"),
                .qmk("TL_LOWR", legend: "Lower"), .momentary(ObbutLayer.function),
                .transparent, .transparent
            )
        }
    }

    /// The navigation layer.
    fileprivate static var lowerLayer: Layer<Domain> {
        Layer(ObbutLayer.lower, name: "Lower", showsHUD: true) {
            Row(keys: transparent(count: 10) + [.delete.style(.destructive), .backspace.style(.destructive)])
            Row(
                .transparent, .transparent, .transparent, .transparent, .transparent, .transparent,
                .left.style(.navigation), .down.style(.navigation),
                .up.style(.navigation), .right.style(.navigation),
                .transparent, .transparent
            )
            Row(keys: transparent(count: 12))
            Row(keys: transparent(count: 11))
        }
    }

    /// The number and symbol layer.
    fileprivate static var raiseLayer: Layer<Domain> {
        Layer(ObbutLayer.raise, name: "Raise", showsHUD: true) {
            Row(
                .grave.style(.symbol), .exclamation.style(.symbol), .at.style(.symbol),
                .leftBracket.style(.symbol), .rightBracket.style(.symbol), .transparent,
                .colon.style(.symbol), .seven.style(.number), .eight.style(.number),
                .nine.style(.number), .minus.style(.symbol), .transparent
            )
            Row(
                .transparent, .hash.style(.symbol), .dollar.style(.symbol),
                .leftParenthesis.style(.symbol), .rightParenthesis.style(.symbol),
                .colon.style(.symbol), .transparent,
                .four.style(.number), .five.style(.number), .six.style(.number),
                .plus.style(.symbol), .equal.style(.symbol)
            )
            Row(
                .transparent, .percent.style(.symbol), .caret.style(.symbol),
                .leftBrace.style(.symbol), .rightBrace.style(.symbol), .transparent,
                .zero.style(.number), .one.style(.number), .two.style(.number),
                .three.style(.number), .period.style(.symbol), .backslash.style(.symbol)
            )
            Row(keys: transparent(count: 11))
        }
    }

    /// The function and firmware-control layer.
    fileprivate static var functionLayer: Layer<Domain> {
        Layer(ObbutLayer.function, name: "Function", showsHUD: true) {
            Row(keys: [.transparent] + (11...15).map(functionKey) + transparent(count: 6))
            Row(
                .bootloader.style(.bootloader),
                functionKey(6), functionKey(7), functionKey(8), functionKey(9), functionKey(10),
                .rgbToggle.style(.increase), .rgbSaturationUp.style(.increase),
                .rgbHueUp.style(.increase), .rgbValueUp.style(.increase),
                .rgbNext.style(.increase), .bootloader.style(.bootloader)
            )
            Row(
                .transparent,
                functionKey(1), functionKey(2), functionKey(3), functionKey(4), functionKey(5),
                .toggle(ObbutLayer.qwerty).style(.gaming),
                .rgbSaturationDown.style(.decrease), .rgbHueDown.style(.decrease),
                .rgbValueDown.style(.decrease), .rgbPrevious.style(.decrease), .transparent
            )
            Row(keys: transparent(count: 11))
        }
    }

    /// Creates a repeated transparent-key sequence.
    fileprivate static func transparent(count: Int) -> [Key<Domain>] {
        Array(repeating: .transparent, count: count)
    }

    /// Creates a styled function key.
    fileprivate static func functionKey(_ number: Int) -> Key<Domain> {
        .function(number).style(.function)
    }
}
