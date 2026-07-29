import ObbutKeymaps
import QMKFirmwareRuntime
import QMKKeymapKit

/// Keychron Q15 Max definition with macOS and Windows base layers.
@QMKFirmware
public enum Q15Firmware {
    public typealias LayerID = Q15Layer

    public static let id: FirmwareID = "com.obbut.keychron-q15-max"
    public static let layout = Q15MaxLayout()
    public static let outputName: StaticString = "keychron_q15_max_ansi_encoder_obbut"

    public static var keymap: some KeymapDefinition {
        Layer(Q15Layer.macBase, name: "macOS") {
            Row(
                .screenshot, .one, .two, .three, .four, .five, .six, .seven,
                .eight, .nine, .zero, .minus, .backspace, .playPause, .tab, .q, .w,
                .e, .r, .t, .y, .u
            )
            Row(
                .i, .o, .p, .leftBracket, .rightBracket, .backslash,
                .escapeAerospace, .a, .s, .d, .f, .g, .h, .j, .k, .l,
                .semicolon, .quote, .return, .leftShift, .z, .x
            )
            Row(
                .c, .v, .b, .n, .m, .comma, .period, .slash, .rightShift, .up,
                .delete, .leftControl, .no, .leftOption, .leftCommand, .space,
                .layerTap(Q15Layer.raise, key: .space),
                .momentary(Q15Layer.macFunction), .momentary(Q15Layer.commonFunction),
                .left, .down, .right
            )
        }
        Layer(Q15Layer.windowsBase, name: "Windows") {
            Row(
                .printScreen, .one, .two, .three, .four, .five, .six, .seven,
                .eight, .nine, .zero, .minus, .backspace, .playPause, .tab, .q, .w,
                .e, .r, .t, .y, .u
            )
            Row(
                .i, .o, .p, .leftBracket, .rightBracket, .backslash, .escape,
                .a, .s, .d, .f, .g, .h, .j, .k, .l, .semicolon, .quote, .return,
                .leftShift, .z, .x
            )
            Row(
                .c, .v, .b, .n, .m, .comma, .period, .slash, .rightShift, .up,
                .delete, .leftControl, .leftCommand, .no, .leftOption, .space,
                .layerTap(Q15Layer.raise, key: .space),
                .momentary(Q15Layer.windowsFunction), .momentary(Q15Layer.commonFunction),
                .left, .down, .right
            )
        }
        Layer(Q15Layer.macFunction, name: "macOS Function", showsHUD: true) {
            Row {
                Key.qmk(.keychronRGBToggle, legend: "RGB").style(.increase)
                Key.qmk(.brightnessDown, legend: "Brightness −").style(.decrease)
                Key.qmk(.brightnessUp, legend: "Brightness +").style(.increase)
                Key.qmk(.missionControl, legend: "Mission Control")
                Key.qmk(.launchpad, legend: "Launchpad")
                Key.qmk(.keychronRGBValueDown, legend: "Brightness −").style(.decrease)
                Key.qmk(.keychronRGBValueUp, legend: "Brightness +").style(.increase)
                Key.previousTrack
                Key.playPause
                Key.nextTrack
                Key.mute
                Key.volumeDown
                Key.equal
                Key.transparent
                Key.bootloader.style(.bootloader)
                Key.bluetoothHost1
                Key.bluetoothHost2
                Key.bluetoothHost3
                Key.wireless24GHz
                Repeat(.transparent, count: 47)
            }
        }
        Layer(Q15Layer.windowsFunction, name: "Windows Function", showsHUD: true) {
            Row {
                Key.qmk(.keychronRGBToggle, legend: "RGB").style(.increase)
                Key.qmk(.brightnessDown, legend: "Brightness −").style(.decrease)
                Key.qmk(.brightnessUp, legend: "Brightness +").style(.increase)
                Key.qmk(.taskView, legend: "Task View")
                Key.qmk(.fileExplorer, legend: "File Explorer")
                Key.qmk(.keychronRGBValueDown, legend: "Brightness −").style(.decrease)
                Key.qmk(.keychronRGBValueUp, legend: "Brightness +").style(.increase)
                Key.previousTrack
                Key.playPause
                Key.nextTrack
                Key.mute
                Key.volumeDown
                Key.equal
                Key.transparent
                Key.bootloader.style(.bootloader)
                Key.bluetoothHost1
                Key.bluetoothHost2
                Key.bluetoothHost3
                Key.wireless24GHz
                Repeat(.transparent, count: 47)
            }
        }
        Layer(Q15Layer.commonFunction, name: "Function", showsHUD: true) {
            Row {
                Key.transparent
                FunctionKeys(1...12, style: SolidKeyStyle.function)
                Key.transparent
                Repeat(.transparent, count: 27)
                Repeat(.transparent, count: 5)
                Key.batteryLevel
                Repeat(.transparent, count: 6)
                Key.qmk(.keychronRGBValueUp, legend: "Brightness +").style(.increase)
                Key.transparent
                Repeat(.transparent, count: 8)
                Key.qmk(.keychronRGBSpeedDown, legend: "Speed −").style(.decrease)
                Key.qmk(.keychronRGBValueDown, legend: "Brightness −").style(.decrease)
                Key.qmk(.keychronRGBSpeedUp, legend: "Speed +").style(.increase)
            }
        }
        Layer(Q15Layer.raise, name: "Raise", showsHUD: true) {
            Row {
                Repeat(.transparent, count: 14)
                Key.grave.style(.symbol)
                Key.exclamation.style(.symbol)
                Key.at.style(.symbol)
                Key.leftBrace.style(.symbol)
                Key.rightBrace.style(.symbol)
                Key.transparent
                Key.colon.style(.symbol)
                Key.seven.style(.number)
                Key.eight.style(.number)
                Key.nine.style(.number)
                Key.minus.style(.symbol)
                Repeat(.transparent, count: 5)
                Key.hash.style(.symbol)
                Key.dollar.style(.symbol)
                Key.leftParenthesis.style(.symbol)
                Key.rightParenthesis.style(.symbol)
                Key.transparent
                Key.four.style(.number)
                Key.five.style(.number)
                Key.six.style(.number)
                Key.plus.style(.symbol)
                Key.equal.style(.symbol)
                Repeat(.transparent, count: 3)
                Key.percent.style(.symbol)
                Key.caret.style(.symbol)
                Key.leftBracket.style(.symbol)
                Key.rightBracket.style(.symbol)
                Key.zero.style(.number)
                Key.one.style(.number)
                Key.two.style(.number)
                Key.three.style(.number)
                Key.period.style(.symbol)
                Key.backslash.style(.symbol)
                Repeat(.transparent, count: 13)
            }
        }
        Q15Firmware.q15Encoder(index: 0, id: "left")
        Q15Firmware.q15Encoder(index: 1, id: "right")
    }

    public static var features: some FirmwareFeatureSet {
        ObbutKeymapCompanion()
        ObbutLayerLighting()
        KeychronCommonFeature()
    }

    @usableFromInline
    @_alwaysEmitIntoClient
    @inline(__always)
    internal static func q15Encoder(
        index: Int,
        id: StaticString
    ) -> Q15EncoderDefinition {
        Q15EncoderDefinition(index: index, id: id)
    }
}

@usableFromInline
internal struct Q15EncoderDefinition: KeymapDefinition {
    @usableFromInline internal let index: Int
    @usableFromInline internal let id: StaticString

    @usableFromInline
    internal init(index: Int, id: StaticString) {
        self.index = index
        self.id = id
    }

    @usableFromInline internal var layerCount: Int { 0 }
    @usableFromInline internal var encoderCount: Int { 1 }

    @usableFromInline
    internal func layer(at ordinal: Int) -> KeymapLayerMetadata? { nil }

    @usableFromInline
    internal func key(at index: Int, onLayer layerOrdinal: Int) -> Key? { nil }

    @usableFromInline
    internal func encoder(at ordinal: Int) -> KeymapEncoderMetadata? {
        ordinal == 0 ? KeymapEncoderMetadata(index: index, id: id) : nil
    }

    @usableFromInline
    internal func encoderMapping(onLayer layerOrdinal: Int, encoderAt encoderOrdinal: Int) -> On? {
        guard encoderOrdinal == 0 else { return nil }
        return switch layerOrdinal {
        case Int(Q15Layer.macBase.rawValue):
            On(Q15Layer.macBase, counterclockwise: .volumeDown, clockwise: .volumeUp)
        case Int(Q15Layer.windowsBase.rawValue):
            On(Q15Layer.windowsBase, counterclockwise: .volumeDown, clockwise: .volumeUp)
        case Int(Q15Layer.macFunction.rawValue):
            On(
                Q15Layer.macFunction,
                counterclockwise: .qmk(.keychronRGBValueDown, legend: "Brightness −"),
                clockwise: .qmk(.keychronRGBValueUp, legend: "Brightness +")
            )
        case Int(Q15Layer.windowsFunction.rawValue):
            On(
                Q15Layer.windowsFunction,
                counterclockwise: .qmk(.keychronRGBValueDown, legend: "Brightness −"),
                clockwise: .qmk(.keychronRGBValueUp, legend: "Brightness +")
            )
        case Int(Q15Layer.commonFunction.rawValue):
            On(
                Q15Layer.commonFunction,
                counterclockwise: .qmk(.keychronRGBValueDown, legend: "Brightness −"),
                clockwise: .qmk(.keychronRGBValueUp, legend: "Brightness +")
            )
        case Int(Q15Layer.raise.rawValue):
            On(Q15Layer.raise, counterclockwise: .volumeDown, clockwise: .volumeUp)
        default:
            nil
        }
    }
}

#if canImport(SwiftUI) && !hasFeature(Embedded)
import QMKKeymapRenderer
import SwiftUI

#Preview("Q15 Max") {
    KeymapPreviewView(Q15Firmware.self)
}
#endif
