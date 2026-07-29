import ObbutKeymaps
import QMKFirmwareRuntime
import QMKKeymapKit

/// ZSA Planck EZ Glow definition using the two-unit center-space layout.
@QMKFirmware
public enum PlanckFirmware {
    public static let id: FirmwareID = "com.obbut.planck-ez-glow"
    public static let layout = PlanckEZGlowLayout()
    public static let outputName: StaticString = "zsa_planck_ez_glow_obbut"

    public static var keymap: some KeymapDefinition {
        Layer(name: "Default") {
            Row(.tab, .q, .w, .f, .p, .b, .j, .l, .u, .y, .semicolon, .backspace)
            Row(.escape, .a, .r, .s, .t, .g, .m, .n, .e, .i, .o, .quote)
            Row(.leftShift, .z, .x, .c, .d, .v, .k, .h, .comma, .period, .slash, .return)
            Row(
                .screenshot, .leftControl, .leftOption, .aerospace,
                .leftCommand, .space,
                .qmk(.triLayerUpper, legend: "Raise"), .qmk(.triLayerLower, legend: "Lower"),
                .momentary(LayerID.function), .rightOption, .delete
            )
        }

        Layer(name: "QWERTY") {
            Row(.tab, .q, .w.style(.gaming), .e, .r, .t, .y, .u, .i, .o, .p, .backspace)
            Row(
                .escape, .a.style(.gaming), .s.style(.gaming), .d.style(.gaming),
                .f, .g, .h, .j, .k, .l, .semicolon, .quote
            )
            Row(.leftShift, .z, .x, .c, .v, .b, .n, .m, .comma, .period, .slash, .return)
            Row(
                .leftControl.style(.gaming), .leftOption.style(.gaming),
                .space.style(.gaming), .space.style(.gaming), .space.style(.gaming),
                .space.style(.gaming), .qmk(.triLayerUpper, legend: "Raise"),
                .qmk(.triLayerLower, legend: "Lower"), .momentary(LayerID.function),
                .transparent, .transparent
            )
        }

        Layer(name: "Lower", showsHUD: true) {
            Row {
                Repeat(.transparent, count: 10)
                Key.delete.style(.destructive)
                Key.backspace.style(.destructive)
            }
            Row(
                .transparent, .transparent, .transparent, .transparent, .transparent, .transparent,
                .left.style(.navigation), .down.style(.navigation),
                .up.style(.navigation), .right.style(.navigation),
                .transparent, .transparent
            )
            Row { Repeat(.transparent, count: 12) }
            Row { Repeat(.transparent, count: 11) }
        }

        Layer(name: "Raise", showsHUD: true) {
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
                .zero.style(.number), .one.style(.number), .two.style(.number),
                .three.style(.number), .period.style(.symbol), .backslash.style(.symbol)
            )
            Row { Repeat(.transparent, count: 11) }
        }

        Layer(name: "Function", showsHUD: true) {
            Row {
                Key.transparent
                FunctionKeys(11...15, style: SolidKeyStyle.function)
                Repeat(.transparent, count: 6)
            }
            Row(
                .bootloader.style(.bootloader),
                PlanckFirmware.functionKey(6), PlanckFirmware.functionKey(7),
                PlanckFirmware.functionKey(8), PlanckFirmware.functionKey(9),
                PlanckFirmware.functionKey(10),
                .rgbToggle.style(.increase), .rgbSaturationUp.style(.increase),
                .rgbHueUp.style(.increase), .rgbValueUp.style(.increase),
                .rgbNext.style(.increase), .bootloader.style(.bootloader)
            )
            Row(
                .transparent,
                PlanckFirmware.functionKey(1), PlanckFirmware.functionKey(2),
                PlanckFirmware.functionKey(3), PlanckFirmware.functionKey(4),
                PlanckFirmware.functionKey(5),
                .toggle(LayerID.qwerty).style(.gaming),
                .rgbSaturationDown.style(.decrease), .rgbHueDown.style(.decrease),
                .rgbValueDown.style(.decrease), .rgbPrevious.style(.decrease), .transparent
            )
            Row { Repeat(.transparent, count: 11) }
        }
    }

    @usableFromInline
    @_alwaysEmitIntoClient
    @inline(__always)
    internal static func functionKey(_ number: Int) -> Key {
        .function(number).style(.function)
    }

    public static var features: some FirmwareFeatureSet {
        ObbutKeymapCompanion()
        ObbutWindowsOverrides()
        ObbutLayerLighting()
        PlanckHardwareFeature()
    }
}

#if canImport(SwiftUI) && !hasFeature(Embedded)
import QMKKeymapRenderer
import SwiftUI

#Preview("Planck EZ") {
    KeymapPreviewView(PlanckFirmware.self)
}
#endif
