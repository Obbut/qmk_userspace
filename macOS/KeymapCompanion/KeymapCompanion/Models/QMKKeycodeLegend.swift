import Foundation

/// Converts compiled QMK keycodes and firmware semantics into compact legends.
enum QMKKeycodeLegend {
    /// Creates a display legend for one downloaded matrix entry.
    /// - Parameter entry: The firmware-owned keymap entry.
    /// - Returns: A compact label with the firmware-provided style.
    static func legend(for entry: FirmwareKeymapEntry) -> KeyLegend {
        KeyLegend(label: label(for: entry), style: entry.style)
    }

    /// Converts semantic overrides and QMK numeric ranges into readable text.
    /// - Parameter entry: The entry to decode.
    /// - Returns: A compact technical label.
    private static func label(for entry: FirmwareKeymapEntry) -> String {
        switch entry.semantic {
        case 1:
            return "Screenshot"
        case 2:
            return "Aerospace"
        default:
            break
        }

        let keycode = entry.keycode
        if let shiftedSymbol = shiftedSymbols[keycode] {
            return shiftedSymbol
        }
        if let basicLabel = basicLabel(for: keycode) {
            return basicLabel
        }

        switch keycode {
        case 0x0100...0x1FFF:
            return modifiedLabel(for: keycode)
        case 0x5220...0x523F:
            return layerName(for: keycode) ?? "MO\(keycode & 0x1F)"
        case 0x5260...0x527F:
            return layerName(for: keycode) ?? "TG\(keycode & 0x1F)"
        case 0x7842:
            return "RGB"
        case 0x7843:
            return "Next"
        case 0x7844:
            return "Prev"
        case 0x7845:
            return "Hue+"
        case 0x7846:
            return "Hue-"
        case 0x7847:
            return "Sat+"
        case 0x7848:
            return "Sat-"
        case 0x7849:
            return "Brt+"
        case 0x784A:
            return "Brt-"
        case 0x7C00:
            return "Boot"
        default:
            return String(format: "0x%04X", keycode)
        }
    }

    /// Returns the common QMK basic-key label for a numeric value.
    /// - Parameter keycode: A compiled QMK keycode.
    /// - Returns: The label, or `nil` when another range should decode it.
    private static func basicLabel(for keycode: UInt16) -> String? {
        switch keycode {
        case 0x0000, 0x0001:
            return ""
        case 0x0004...0x001D:
            return String(UnicodeScalar(Int(keycode - 0x0004) + 65)!)
        case 0x001E...0x0026:
            return String(Int(keycode - 0x001D))
        case 0x0027:
            return "0"
        case 0x0028:
            return "ENT"
        case 0x0029:
            return "ESC"
        case 0x002A:
            return "BSPC"
        case 0x002B:
            return "TAB"
        case 0x002C:
            return "SPC"
        case 0x002D:
            return "-"
        case 0x002E:
            return "="
        case 0x002F:
            return "["
        case 0x0030:
            return "]"
        case 0x0031:
            return "\\"
        case 0x0033:
            return ";"
        case 0x0034:
            return "'"
        case 0x0035:
            return "`"
        case 0x0036:
            return ","
        case 0x0037:
            return "."
        case 0x0038:
            return "/"
        case 0x003A...0x0045:
            return "F\(keycode - 0x0039)"
        case 0x0046:
            return "PrtSc"
        case 0x0049:
            return "Ins"
        case 0x004A:
            return "Home"
        case 0x004B:
            return "PgUp"
        case 0x004C:
            return "DEL"
        case 0x004D:
            return "End"
        case 0x004E:
            return "PgDn"
        case 0x004F:
            return "→"
        case 0x0050:
            return "←"
        case 0x0051:
            return "↓"
        case 0x0052:
            return "↑"
        case 0x0068...0x0073:
            return "F\(keycode - 0x0068 + 13)"
        case 0x007F, 0x00A8:
            return "Mute"
        case 0x0080, 0x00A9:
            return "Vol+"
        case 0x0081, 0x00AA:
            return "Vol-"
        case 0x00AB:
            return "Next"
        case 0x00AC:
            return "Prev"
        case 0x00AE:
            return "Play"
        case 0x00D1:
            return "Click"
        case 0x00E0:
            return "LCTL"
        case 0x00E1:
            return "LSFT"
        case 0x00E2:
            return "LALT"
        case 0x00E3:
            return "LGUI"
        case 0x00E4:
            return "RCTL"
        case 0x00E5:
            return "RSFT"
        case 0x00E6:
            return "RALT"
        case 0x00E7:
            return "RGUI"
        default:
            return nil
        }
    }

    /// Formats QMK's compact modifier-plus-basic-key range.
    /// - Parameter keycode: A keycode in `QK_MODS`.
    /// - Returns: Modifier symbols followed by the underlying basic key.
    private static func modifiedLabel(for keycode: UInt16) -> String {
        let modifiers = UInt8((keycode >> 8) & 0x1F)
        var prefix = ""
        if modifiers & 0x01 != 0 { prefix += "⌃" }
        if modifiers & 0x02 != 0 { prefix += "⇧" }
        if modifiers & 0x04 != 0 { prefix += "⌥" }
        if modifiers & 0x08 != 0 { prefix += "⌘" }
        let base = basicLabel(for: keycode & 0x00FF) ?? String(format: "%02X", keycode & 0x00FF)
        return prefix + base
    }

    /// Resolves a layer-switch keycode through the shared layer identifiers.
    /// - Parameter keycode: A QMK layer-switch keycode.
    /// - Returns: The compact layer legend, if the layer is supported.
    private static func layerName(for keycode: UInt16) -> String? {
        KeymapLayer(rawValue: UInt8(keycode & 0x1F))?.legendName
    }

    /// US ANSI shifted aliases used by the current firmware keymaps.
    private static let shiftedSymbols: [UInt16: String] = [
        0x021E: "!",
        0x021F: "@",
        0x0220: "#",
        0x0221: "$",
        0x0222: "%",
        0x0223: "^",
        0x0224: "&",
        0x0225: "*",
        0x0226: "(",
        0x0227: ")",
        0x022D: "_",
        0x022E: "+",
        0x022F: "{",
        0x0230: "}",
        0x0231: "|",
        0x0233: ":",
        0x0234: "\"",
        0x0235: "~",
        0x0236: "<",
        0x0237: ">",
        0x0238: "?"
    ]
}
