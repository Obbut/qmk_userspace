import QMKKeymapKit

/// The five reusable typing and control layers shared by Kyria and Elora.
public struct SharedHalcyonLayers: Sendable {
    internal let layout: HalcyonLayoutKind

    /// Includes a physical number row for the Elora layout.
    ///
    /// - Parameter layout: Whether a physical number row is present.
    public init(layout: HalcyonLayoutKind) {
        self.layout = layout
    }
}

extension SharedHalcyonLayers {
    internal static func baseLayer(layout: HalcyonLayoutKind) -> some KeymapDefinition {
        Layer(ObbutLayer.base, name: "Default", context: layout) { layout in
            if layout == .elora {
                Row(.grave, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .zero, .minus)
            }
            Row(.tab, .q, .w, .f, .p, .b, .j, .l, .u, .y, .semicolon, .backspace)
            Row(.escape, .a, .r, .s, .t, .g, .m, .n, .e, .i, .o, .quote)
            Row(
                .leftShift, .z, .x, .c, .d, .v,
                .leftOption, .pointerLeftClick,
                .momentary(ObbutLayer.function), .no,
                .k, .h, .comma, .period, .slash, .return
            )
            Row(
                .screenshot, .leftControl, .leftCommand, .aerospace, .space,
                .no, .space, .momentary(ObbutLayer.raise), .momentary(ObbutLayer.lower), .no
            )
            Row(.no, .no, .no, .no, .no, .mute, .no, .no, .no, .no)
        }
    }

    internal static func qwertyLayer(layout: HalcyonLayoutKind) -> some KeymapDefinition {
        Layer(ObbutLayer.qwerty, name: "QWERTY", context: layout) { layout in
            if layout == .elora {
                Row(.grave, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .zero, .minus)
            }
            Row(
                .tab, .q, .w.style(.gaming), .e, .r, .t,
                .y, .u, .i, .o, .p, .backspace
            )
            Row(
                .escape, .a.style(.gaming), .s.style(.gaming), .d.style(.gaming), .f, .g,
                .h, .j, .k, .l, .semicolon, .quote
            )
            Row(
                .leftShift, .z, .x, .c, .v, .b,
                .leftOption.style(.gaming), .pointerLeftClick,
                .momentary(ObbutLayer.function), .no,
                .n, .m, .comma, .period, .slash, .return
            )
            Row(
                .leftControl.style(.gaming), .leftOption.style(.gaming),
                .space.style(.gaming), .space.style(.gaming), .space.style(.gaming),
                .no, .space, .momentary(ObbutLayer.raise), .momentary(ObbutLayer.lower), .no
            )
            Row(.no, .no, .no, .no, .no, .mute, .no, .no, .no, .no)
        }
    }

    internal static func lowerLayer(layout: HalcyonLayoutKind) -> some KeymapDefinition {
        Layer(ObbutLayer.lower, name: "Lower", showsHUD: true, context: layout) { layout in
            if layout == .elora {
                Row { Repeat(.transparent, count: 12) }
            }
            Row {
                Repeat(.transparent, count: 10)
                Key.delete.style(.destructive)
                Key.backspace.style(.destructive)
            }
            Row {
                Repeat(.transparent, count: 6)
                Key.left.style(.navigation)
                Key.down.style(.navigation)
                Key.up.style(.navigation)
                Key.right.style(.navigation)
                Repeat(.transparent, count: 2)
            }
            Row { Repeat(.transparent, count: 16) }
            Row { Repeat(.transparent, count: 10) }
            Row {
                Repeat(.transparent, count: 5)
                Key.playPause
                Repeat(.transparent, count: 4)
            }
        }
    }

    internal static func raiseLayer(layout: HalcyonLayoutKind) -> some KeymapDefinition {
        Layer(ObbutLayer.raise, name: "Raise", showsHUD: true, context: layout) { layout in
            if layout == .elora {
                Row { Repeat(.transparent, count: 12) }
            }
            Row(
                .grave.style(.symbol), .exclamation.style(.symbol), .at.style(.symbol),
                .leftBrace.style(.symbol), .rightBrace.style(.symbol), .transparent,
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
                .leftBracket.style(.symbol), .rightBracket.style(.symbol), .transparent,
                .transparent, .transparent, .transparent, .transparent,
                .zero.style(.number), .one.style(.number), .two.style(.number),
                .three.style(.number), .period.style(.symbol), .backslash.style(.symbol)
            )
            Row { Repeat(.transparent, count: 10) }
            Row { Repeat(.transparent, count: 10) }
        }
    }

    internal static func functionLayer(layout: HalcyonLayoutKind) -> some KeymapDefinition {
        Layer(ObbutLayer.function, name: "Function", showsHUD: true, context: layout) { layout in
            if layout == .elora {
                Row { Repeat(.transparent, count: 12) }
            }
            Row {
                Key.transparent
                FunctionKeys(11...15, style: SolidKeyStyle.function)
                Repeat(.transparent, count: 6)
            }
            Row(
                .bootloader.style(.bootloader),
                .function(6).style(.function), .function(7).style(.function),
                .function(8).style(.function), .function(9).style(.function),
                .function(10).style(.function),
                .qmk(.rgbMatrixToggle, legend: "RGB").style(.increase),
                .qmk(.rgbMatrixSaturationUp, legend: "Sat+").style(.increase),
                .qmk(.rgbMatrixHueUp, legend: "Hue+").style(.increase),
                .qmk(.rgbMatrixValueUp, legend: "Brt+").style(.increase),
                .qmk(.rgbMatrixNext, legend: "Next").style(.increase),
                .bootloader.style(.bootloader)
            )
            Row {
                Key.transparent
                FunctionKeys(1...5, style: SolidKeyStyle.function)
                Key.transparent
                Key.toggle(ObbutLayer.qwerty).style(.gaming)
                Repeat(.transparent, count: 2)
                Key.transparent
                Key.qmk(.rgbMatrixSaturationDown, legend: "Sat−").style(.decrease)
                Key.qmk(.rgbMatrixHueDown, legend: "Hue−").style(.decrease)
                Key.qmk(.rgbMatrixValueDown, legend: "Brt−").style(.decrease)
                Key.qmk(.rgbMatrixPrevious, legend: "Previous").style(.decrease)
                Key.transparent
            }
            Row { Repeat(.transparent, count: 10) }
            Row { Repeat(.transparent, count: 10) }
        }
    }
}
