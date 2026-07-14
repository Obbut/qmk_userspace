import Foundation

/// A converter from compiled QMK keycodes and firmware semantics to compact legends.
enum QMKKeycodeLegend {
    /// Returns the renderer legend for a firmware keymap entry.
    ///
    /// - Parameter entry: The firmware keymap entry to describe.
    ///
    /// - Returns: A compact renderer legend.
    static func legend(for entry: FirmwareKeymapEntry) -> KeyLegend {
        KeyLegend(
            label: label(for: entry),
            symbol: entry.semantic == .none ? symbol(for: entry.keycode) : nil,
            style: entry.style
        )
    }

    /// Returns the fallback text for a firmware keymap entry.
    ///
    /// - Parameter entry: The firmware keymap entry to describe.
    ///
    /// - Returns: Compact fallback text.
    private static func label(for entry: FirmwareKeymapEntry) -> String {
        switch entry.semantic {
        case .screenshot: return "Screenshot"
        case .aerospace: return "Aerospace"
        case .none: break
        }

        let keycode = entry.keycode
        if let shiftedSymbol = shiftedSymbols[keycode] {
            return shiftedSymbol
        }
        if let basicLabel = basicLabel(for: keycode) {
            return basicLabel
        }

        return switch keycode {
        case 0x0100...0x1FFF: modifiedLabel(for: keycode)
        case 0x5220...0x523F: layerName(for: keycode) ?? "MO\(keycode & 0x1F)"
        case 0x5260...0x527F: layerName(for: keycode) ?? "TG\(keycode & 0x1F)"
        case 0x7842: "RGB"
        case 0x7843: "Next"
        case 0x7844: "Prev"
        case 0x7845: "Hue+"
        case 0x7846: "Hue-"
        case 0x7847: "Sat+"
        case 0x7848: "Sat-"
        case 0x7849: "Brt+"
        case 0x784A: "Brt-"
        case 0x7C00: "Boot"
        default: String(format: "0x%04X", keycode)
        }
    }

    /// Returns the fallback text for an unmodified QMK keycode.
    ///
    /// - Parameter keycode: The compiled QMK keycode.
    ///
    /// - Returns: Compact text, or `nil` when the keycode is not recognized.
    private static func basicLabel(for keycode: UInt16) -> String? {
        return switch keycode {
        case 0x0000, 0x0001: ""
        case 0x0004...0x001D:
            UnicodeScalar(Int(keycode - 0x0004) + 65).map { String($0) }
        case 0x001E...0x0026: String(Int(keycode - 0x001D))
        case 0x0027: "0"
        case 0x0028: "Return"
        case 0x0029: "Escape"
        case 0x002A: "Delete"
        case 0x002B: "Tab"
        case 0x002C: "Space"
        case 0x002D: "-"
        case 0x002E: "="
        case 0x002F: "["
        case 0x0030: "]"
        case 0x0031: "\\"
        case 0x0033: ";"
        case 0x0034: "'"
        case 0x0035: "`"
        case 0x0036: ","
        case 0x0037: "."
        case 0x0038: "/"
        case 0x0039: "Caps Lock"
        case 0x003A...0x0045: "F\(keycode - 0x0039)"
        case 0x0046: "PrtSc"
        case 0x0049: "Ins"
        case 0x004A: "Home"
        case 0x004B: "PgUp"
        case 0x004C: "Forward Delete"
        case 0x004D: "End"
        case 0x004E: "PgDn"
        case 0x004F: "→"
        case 0x0050: "←"
        case 0x0051: "↓"
        case 0x0052: "↑"
        case 0x0068...0x0073: "F\(keycode - 0x0068 + 13)"
        case 0x007F, 0x00A8: "Mute"
        case 0x0080, 0x00A9: "Volume Up"
        case 0x0081, 0x00AA: "Volume Down"
        case 0x00AB: "Next Track"
        case 0x00AC: "Previous Track"
        case 0x00AE: "Play or Pause"
        case 0x00D1: "Click"
        case 0x00E0, 0x00E4: "Control"
        case 0x00E1, 0x00E5: "Shift"
        case 0x00E2, 0x00E6: "Option"
        case 0x00E3, 0x00E7: "Command"
        default: nil
        }
    }

    /// Returns the semantic symbol for a compiled QMK keycode.
    ///
    /// - Parameter keycode: The compiled QMK keycode.
    ///
    /// - Returns: A semantic symbol, or `nil` when native iconography is unsuitable.
    private static func symbol(for keycode: UInt16) -> KeySymbol? {
        switch keycode {
        case 0x0028: .returnKey
        case 0x0029: .escape
        case 0x002A: .deleteBackward
        case 0x002B: .tab
        case 0x002C: .space
        case 0x0039: .capsLock
        case 0x004C: .deleteForward
        case 0x004F: .arrowRight
        case 0x0050: .arrowLeft
        case 0x0051: .arrowDown
        case 0x0052: .arrowUp
        case 0x007F, 0x00A8: .mute
        case 0x0080, 0x00A9: .volumeUp
        case 0x0081, 0x00AA: .volumeDown
        case 0x00AB: .nextTrack
        case 0x00AC: .previousTrack
        case 0x00AE: .playPause
        case 0x00E0, 0x00E4: .control
        case 0x00E1, 0x00E5: .shift
        case 0x00E2, 0x00E6: .option
        case 0x00E3, 0x00E7: .command
        default: nil
        }
    }

    /// Returns the compact legend for a QMK keycode with encoded modifiers.
    ///
    /// - Parameter keycode: The compiled QMK keycode.
    ///
    /// - Returns: A modifier prefix followed by the basic key legend.
    private static func modifiedLabel(for keycode: UInt16) -> String {
        let modifiers = UInt8((keycode >> 8) & 0x1F)
        var prefix = ""
        if modifiers & 0x01 != 0 { prefix += "⌃" }
        if modifiers & 0x02 != 0 { prefix += "⇧" }
        if modifiers & 0x04 != 0 { prefix += "⌥" }
        if modifiers & 0x08 != 0 { prefix += "⌘" }
        let base =
            basicLabel(for: keycode & 0x00FF)
            ?? String(format: "%02X", keycode & 0x00FF)
        return prefix + base
    }

    /// Returns the display name for the layer encoded in a QMK layer keycode.
    ///
    /// - Parameter keycode: The compiled QMK layer keycode.
    ///
    /// - Returns: The layer name, or `nil` when the layer is unknown.
    private static func layerName(for keycode: UInt16) -> String? {
        KeymapLayer(rawValue: UInt8(keycode & 0x1F))?.legendName
    }

    /// Shifted keycodes and their printable legends.
    private static let shiftedSymbols: [UInt16: String] = [
        0x021E: "!", 0x021F: "@", 0x0220: "#", 0x0221: "$",
        0x0222: "%", 0x0223: "^", 0x0224: "&", 0x0225: "*",
        0x0226: "(", 0x0227: ")", 0x022D: "_", 0x022E: "+",
        0x022F: "{", 0x0230: "}", 0x0231: "|", 0x0233: ":",
        0x0234: "\"", 0x0235: "~", 0x0236: "<", 0x0237: ">",
        0x0238: "?",
    ]
}
