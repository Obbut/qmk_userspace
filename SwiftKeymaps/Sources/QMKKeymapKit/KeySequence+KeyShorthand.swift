/// Makes `Key` shorthand available when a variadic row element is inferred
/// through its `KeySequence` constraint.
extension KeySequence where Self == Key {
    public static var no: Key { Key.no }
    public static var transparent: Key { Key.transparent }

    public static var a: Key { Key.a }
    public static var b: Key { Key.b }
    public static var c: Key { Key.c }
    public static var d: Key { Key.d }
    public static var e: Key { Key.e }
    public static var f: Key { Key.f }
    public static var g: Key { Key.g }
    public static var h: Key { Key.h }
    public static var i: Key { Key.i }
    public static var j: Key { Key.j }
    public static var k: Key { Key.k }
    public static var l: Key { Key.l }
    public static var m: Key { Key.m }
    public static var n: Key { Key.n }
    public static var o: Key { Key.o }
    public static var p: Key { Key.p }
    public static var q: Key { Key.q }
    public static var r: Key { Key.r }
    public static var s: Key { Key.s }
    public static var t: Key { Key.t }
    public static var u: Key { Key.u }
    public static var v: Key { Key.v }
    public static var w: Key { Key.w }
    public static var x: Key { Key.x }
    public static var y: Key { Key.y }
    public static var z: Key { Key.z }

    public static var one: Key { Key.one }
    public static var two: Key { Key.two }
    public static var three: Key { Key.three }
    public static var four: Key { Key.four }
    public static var five: Key { Key.five }
    public static var six: Key { Key.six }
    public static var seven: Key { Key.seven }
    public static var eight: Key { Key.eight }
    public static var nine: Key { Key.nine }
    public static var zero: Key { Key.zero }

    public static var `return`: Key { Key.return }
    public static var escape: Key { Key.escape }
    public static var backspace: Key { Key.backspace }
    public static var tab: Key { Key.tab }
    public static var space: Key { Key.space }
    public static var minus: Key { Key.minus }
    public static var equal: Key { Key.equal }
    public static var leftBracket: Key { Key.leftBracket }
    public static var rightBracket: Key { Key.rightBracket }
    public static var backslash: Key { Key.backslash }
    public static var semicolon: Key { Key.semicolon }
    public static var quote: Key { Key.quote }
    public static var grave: Key { Key.grave }
    public static var comma: Key { Key.comma }
    public static var period: Key { Key.period }
    public static var slash: Key { Key.slash }
    public static var printScreen: Key { Key.printScreen }
    public static var delete: Key { Key.delete }
    public static var right: Key { Key.right }
    public static var left: Key { Key.left }
    public static var down: Key { Key.down }
    public static var up: Key { Key.up }

    public static var leftControl: Key { Key.leftControl }
    public static var leftShift: Key { Key.leftShift }
    public static var leftOption: Key { Key.leftOption }
    public static var leftCommand: Key { Key.leftCommand }
    public static var rightControl: Key { Key.rightControl }
    public static var rightShift: Key { Key.rightShift }
    public static var rightOption: Key { Key.rightOption }
    public static var rightCommand: Key { Key.rightCommand }

    public static var mute: Key { Key.mute }
    public static var volumeUp: Key { Key.volumeUp }
    public static var volumeDown: Key { Key.volumeDown }
    public static var keyboardVolumeUp: Key { Key.keyboardVolumeUp }
    public static var keyboardVolumeDown: Key { Key.keyboardVolumeDown }
    public static var nextTrack: Key { Key.nextTrack }
    public static var previousTrack: Key { Key.previousTrack }
    public static var playPause: Key { Key.playPause }
    public static var bootloader: Key { Key.bootloader }

    public static var exclamation: Key { Key.exclamation }
    public static var at: Key { Key.at }
    public static var hash: Key { Key.hash }
    public static var dollar: Key { Key.dollar }
    public static var percent: Key { Key.percent }
    public static var caret: Key { Key.caret }
    public static var leftParenthesis: Key { Key.leftParenthesis }
    public static var rightParenthesis: Key { Key.rightParenthesis }
    public static var leftBrace: Key { Key.leftBrace }
    public static var rightBrace: Key { Key.rightBrace }
    public static var colon: Key { Key.colon }
    public static var plus: Key { Key.plus }

    public static var rgbToggle: Key { Key.rgbToggle }
    public static var rgbNext: Key { Key.rgbNext }
    public static var rgbPrevious: Key { Key.rgbPrevious }
    public static var rgbHueUp: Key { Key.rgbHueUp }
    public static var rgbHueDown: Key { Key.rgbHueDown }
    public static var rgbSaturationUp: Key { Key.rgbSaturationUp }
    public static var rgbSaturationDown: Key { Key.rgbSaturationDown }
    public static var rgbValueUp: Key { Key.rgbValueUp }
    public static var rgbValueDown: Key { Key.rgbValueDown }
    public static var rgbSpeedUp: Key { Key.rgbSpeedUp }
    public static var rgbSpeedDown: Key { Key.rgbSpeedDown }

    public static func function(_ number: Int) -> Key {
        Key.function(number)
    }

    public static func momentary<ID: FirmwareLayerID>(_ layer: ID) -> Key {
        Key.momentary(layer)
    }

    public static func toggle<ID: FirmwareLayerID>(_ layer: ID) -> Key {
        Key.toggle(layer)
    }

    public static func layerTap<ID: FirmwareLayerID>(_ layer: ID, key: Key) -> Key {
        Key.layerTap(layer, key: key)
    }

    public static func qmk(
        _ keycode: QMKKeycode,
        legend: Legend? = nil
    ) -> Key {
        Key.qmk(keycode, legend: legend)
    }
}
