import ObbutKeymaps
import QMKFirmwareRuntime
import QMKKeymapKit

/// Keychron Q15 Max definition with macOS and Windows base layers.
public enum Q15Firmware: QMKFirmware {
    public typealias Domain = ObbutKeymapDomain

    public static let id = "com.obbut.keychron-q15-max"
    public static let layout: LayoutDescriptor = .keychronQ15Max
    public static let outputName = "keychron_q15_max_ansi_encoder_obbut"

    public static var keymap: Keymap<Domain> {
        Layer(Q15Layer.macBase, name: "macOS") {
            Row(keys: [
                ObbutKey.screenshot, .one, .two, .three, .four, .five, .six,
                .seven, .eight, .nine, .zero, .minus, .backspace, .playPause,
                .tab, .q, .w, .e, .r, .t, .y, .u, .i, .o, .p,
                .leftBracket, .rightBracket, .backslash,
                ObbutKey.escapeAerospace, .a, .s, .d, .f, .g, .h, .j, .k, .l,
                .semicolon, .quote, .return,
                .leftShift, .z, .x, .c, .v, .b, .n, .m, .comma, .period,
                .slash, .rightShift, .up, .delete,
                .leftControl, .no, .leftOption, .leftCommand, .space,
                .layerTap(Q15Layer.raise, key: .space),
                .momentary(Q15Layer.macFunction), .momentary(Q15Layer.commonFunction),
                .left, .down, .right,
            ])
        }
        Layer(Q15Layer.windowsBase, name: "Windows") {
            Row(keys: [
                .printScreen, .one, .two, .three, .four, .five, .six,
                .seven, .eight, .nine, .zero, .minus, .backspace, .playPause,
                .tab, .q, .w, .e, .r, .t, .y, .u, .i, .o, .p,
                .leftBracket, .rightBracket, .backslash,
                .escape, .a, .s, .d, .f, .g, .h, .j, .k, .l,
                .semicolon, .quote, .return,
                .leftShift, .z, .x, .c, .v, .b, .n, .m, .comma, .period,
                .slash, .rightShift, .up, .delete,
                .leftControl, .leftCommand, .no, .leftOption, .space,
                .layerTap(Q15Layer.raise, key: .space),
                .momentary(Q15Layer.windowsFunction), .momentary(Q15Layer.commonFunction),
                .left, .down, .right,
            ])
        }
        Layer(Q15Layer.macFunction, name: "macOS Function", showsHUD: true) {
            Row(
                keys: [
                    .rgbToggle.style(.increase),
                    .qmk("KC_BRID", legend: "Brightness −", style: .decrease),
                    .qmk("KC_BRIU", legend: "Brightness +", style: .increase),
                    .qmk("KC_MCTRL", legend: "Mission Control"),
                    .qmk("KC_LPAD", legend: "Launchpad"),
                    .rgbValueDown.style(.decrease), .rgbValueUp.style(.increase),
                    .previousTrack, .playPause, .nextTrack, .mute, .volumeDown, .equal, .transparent,
                    .bootloader.style(.bootloader),
                    ObbutKey.bluetoothHost1, ObbutKey.bluetoothHost2, ObbutKey.bluetoothHost3,
                    ObbutKey.wireless24GHz,
                ] + transparent(count: 47))
        }
        Layer(Q15Layer.windowsFunction, name: "Windows Function", showsHUD: true) {
            Row(
                keys: [
                    .rgbToggle.style(.increase),
                    .qmk("KC_BRID", legend: "Brightness −", style: .decrease),
                    .qmk("KC_BRIU", legend: "Brightness +", style: .increase),
                    .qmk("KC_TASK", legend: "Task View"),
                    .qmk("KC_FILE", legend: "File Explorer"),
                    .rgbValueDown.style(.decrease), .rgbValueUp.style(.increase),
                    .previousTrack, .playPause, .nextTrack, .mute, .volumeDown, .equal, .transparent,
                    .bootloader.style(.bootloader),
                    ObbutKey.bluetoothHost1, ObbutKey.bluetoothHost2, ObbutKey.bluetoothHost3,
                    ObbutKey.wireless24GHz,
                ] + transparent(count: 47))
        }
        Layer(Q15Layer.commonFunction, name: "Function", showsHUD: true) {
            Row(
                keys: [.transparent]
                    + (1...12).map { Key<Domain>.function($0).style(.function) }
                    + [.transparent]
                    + transparent(count: 14)
                    + transparent(count: 13)
                    + [
                        .transparent, .transparent, .transparent, .transparent, .transparent,
                        ObbutKey.batteryLevel,
                    ]
                    + transparent(count: 6)
                    + [.rgbValueUp.style(.increase), .transparent]
                    + transparent(count: 8)
                    + [
                        .rgbSpeedDown.style(.decrease),
                        .rgbValueDown.style(.decrease),
                        .rgbSpeedUp.style(.increase),
                    ]
            )
        }
        Layer(Q15Layer.raise, name: "Raise", showsHUD: true) {
            Row(
                keys: transparent(count: 14)
                    + [
                        .grave.style(.symbol), .exclamation.style(.symbol), .at.style(.symbol),
                        .leftBracket.style(.symbol), .rightBracket.style(.symbol), .transparent,
                        .colon.style(.symbol), .seven.style(.number), .eight.style(.number),
                        .nine.style(.number), .minus.style(.symbol),
                    ]
                    + transparent(count: 3)
                    + [
                        .transparent, .transparent, .hash.style(.symbol), .dollar.style(.symbol),
                        .leftParenthesis.style(.symbol), .rightParenthesis.style(.symbol), .transparent,
                        .four.style(.number), .five.style(.number), .six.style(.number),
                        .plus.style(.symbol), .equal.style(.symbol), .transparent,
                    ]
                    + [
                        .transparent, .transparent, .percent.style(.symbol), .caret.style(.symbol),
                        .leftBrace.style(.symbol), .rightBrace.style(.symbol),
                        .zero.style(.number), .one.style(.number), .two.style(.number),
                        .three.style(.number), .period.style(.symbol), .backslash.style(.symbol),
                        .transparent, .transparent,
                    ]
                    + transparent(count: 11)
            )
        }
        q15Encoder(index: 0, id: "left")
        q15Encoder(index: 1, id: "right")
    }

    public static var configuration: QMKConfiguration {
        QMKConfiguration {
            ObbutQ15Configuration()
        }
    }

    public static var features: FirmwareFeatures {
        ObbutKeymapCompanion()
        ObbutLayerLighting()
        KeychronCommonFeature()
    }

    fileprivate static func q15Encoder(index: Int, id: String) -> Encoder<Domain> {
        Encoder(index, id: id) {
            On(Q15Layer.macBase, counterclockwise: .volumeDown, clockwise: .volumeUp)
            On(Q15Layer.windowsBase, counterclockwise: .volumeDown, clockwise: .volumeUp)
            On(Q15Layer.macFunction, counterclockwise: .rgbValueDown, clockwise: .rgbValueUp)
            On(Q15Layer.windowsFunction, counterclockwise: .rgbValueDown, clockwise: .rgbValueUp)
            On(Q15Layer.commonFunction, counterclockwise: .rgbValueDown, clockwise: .rgbValueUp)
            On(Q15Layer.raise, counterclockwise: .volumeDown, clockwise: .volumeUp)
        }
    }

    fileprivate static func transparent(count: Int) -> [Key<Domain>] {
        Array(repeating: .transparent, count: count)
    }
}

#if canImport(SwiftUI) && !QMK_DIRECT_HOST_BUILD
import QMKKeymapRenderer
import SwiftUI

#Preview("Q15 Max") {
    KeymapPreviewView(Q15Firmware.self)
}
#endif
