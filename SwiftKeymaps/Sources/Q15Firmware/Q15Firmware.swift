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
            MacBaseKeys()
        }
        Layer(Q15Layer.windowsBase, name: "Windows") {
            WindowsBaseKeys()
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
                ObbutKey.bluetoothHost1
                ObbutKey.bluetoothHost2
                ObbutKey.bluetoothHost3
                ObbutKey.wireless24GHz
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
                ObbutKey.bluetoothHost1
                ObbutKey.bluetoothHost2
                ObbutKey.bluetoothHost3
                ObbutKey.wireless24GHz
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
                ObbutKey.batteryLevel
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
                Key.leftBracket.style(.symbol)
                Key.rightBracket.style(.symbol)
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
                Key.leftBrace.style(.symbol)
                Key.rightBrace.style(.symbol)
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

    @usableFromInline
    internal struct MacBaseKeys: KeySequence {
        @usableFromInline
        internal init() {}

        @usableFromInline
        internal var keyCount: Int { 66 }

        @usableFromInline
        internal func key(at index: Int) -> Key? {
            let row1 = Q15Firmware.macBaseRow1
            if index < row1.keyCount { return row1.key(at: index) }

            let row2Index = index - row1.keyCount
            let row2 = Q15Firmware.macBaseRow2
            if row2Index < row2.keyCount { return row2.key(at: row2Index) }

            let row3Index = row2Index - row2.keyCount
            return Q15Firmware.macBaseRow3.key(at: row3Index)
        }
    }

    @usableFromInline
    internal struct WindowsBaseKeys: KeySequence {
        @usableFromInline
        internal init() {}

        @usableFromInline
        internal var keyCount: Int { 66 }

        @usableFromInline
        internal func key(at index: Int) -> Key? {
            let row1 = Q15Firmware.windowsBaseRow1
            if index < row1.keyCount { return row1.key(at: index) }

            let row2Index = index - row1.keyCount
            let row2 = Q15Firmware.windowsBaseRow2
            if row2Index < row2.keyCount { return row2.key(at: row2Index) }

            let row3Index = row2Index - row2.keyCount
            return Q15Firmware.windowsBaseRow3.key(at: row3Index)
        }
    }

    @usableFromInline
    internal static var macBaseRow1: some KeySequence {
        Row {
            ObbutKey.screenshot
            Key.one
            Key.two
            Key.three
            Key.four
            Key.five
            Key.six
            Key.seven
            Key.eight
            Key.nine
            Key.zero
            Key.minus
            Key.backspace
            Key.playPause
            Key.tab
            Key.q
            Key.w
            Key.e
            Key.r
            Key.t
            Key.y
            Key.u
        }
    }

    @usableFromInline
    internal static var macBaseRow2: some KeySequence {
        Row {
            Key.i
            Key.o
            Key.p
            Key.leftBracket
            Key.rightBracket
            Key.backslash
            ObbutKey.escapeAerospace
            Key.a
            Key.s
            Key.d
            Key.f
            Key.g
            Key.h
            Key.j
            Key.k
            Key.l
            Key.semicolon
            Key.quote
            Key.return
            Key.leftShift
            Key.z
            Key.x
        }
    }

    @usableFromInline
    internal static var macBaseRow3: some KeySequence {
        Row {
            Key.c
            Key.v
            Key.b
            Key.n
            Key.m
            Key.comma
            Key.period
            Key.slash
            Key.rightShift
            Key.up
            Key.delete
            Key.leftControl
            Key.no
            Key.leftOption
            Key.leftCommand
            Key.space
            Key.layerTap(Q15Layer.raise, key: .space)
            Key.momentary(Q15Layer.macFunction)
            Key.momentary(Q15Layer.commonFunction)
            Key.left
            Key.down
            Key.right
        }
    }

    @usableFromInline
    internal static var windowsBaseRow1: some KeySequence {
        Row {
            Key.printScreen
            Key.one
            Key.two
            Key.three
            Key.four
            Key.five
            Key.six
            Key.seven
            Key.eight
            Key.nine
            Key.zero
            Key.minus
            Key.backspace
            Key.playPause
            Key.tab
            Key.q
            Key.w
            Key.e
            Key.r
            Key.t
            Key.y
            Key.u
        }
    }

    @usableFromInline
    internal static var windowsBaseRow2: some KeySequence {
        Row {
            Key.i
            Key.o
            Key.p
            Key.leftBracket
            Key.rightBracket
            Key.backslash
            Key.escape
            Key.a
            Key.s
            Key.d
            Key.f
            Key.g
            Key.h
            Key.j
            Key.k
            Key.l
            Key.semicolon
            Key.quote
            Key.return
            Key.leftShift
            Key.z
            Key.x
        }
    }

    @usableFromInline
    internal static var windowsBaseRow3: some KeySequence {
        Row {
            Key.c
            Key.v
            Key.b
            Key.n
            Key.m
            Key.comma
            Key.period
            Key.slash
            Key.rightShift
            Key.up
            Key.delete
            Key.leftControl
            Key.leftCommand
            Key.no
            Key.leftOption
            Key.space
            Key.layerTap(Q15Layer.raise, key: .space)
            Key.momentary(Q15Layer.windowsFunction)
            Key.momentary(Q15Layer.commonFunction)
            Key.left
            Key.down
            Key.right
        }
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
