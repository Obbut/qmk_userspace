import QMKFirmwareHost
import QMKKeymapKit

/// Platform-neutral input for keymap renderers.
public struct KeymapRenderDocument: Equatable, Sendable {
    /// The stable protocol layout identifier.
    public let layoutID: UInt32

    /// The user-facing keyboard name.
    public let displayName: String

    /// The logical renderer width.
    public let canvasWidth: Double

    /// The logical renderer height.
    public let canvasHeight: Double

    /// Layers in firmware index order.
    public let layers: [KeymapRenderLayer]

    /// Physical matrix keys in layout order.
    public let keys: [KeymapRenderKey]

    /// Physical encoders in QMK index order.
    public let encoders: [KeymapRenderEncoder]

    public init(
        layoutID: UInt32,
        displayName: String,
        canvasWidth: Double,
        canvasHeight: Double,
        layers: [KeymapRenderLayer],
        keys: [KeymapRenderKey],
        encoders: [KeymapRenderEncoder]
    ) {
        self.layoutID = layoutID
        self.displayName = displayName
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
        self.layers = layers
        self.keys = keys
        self.encoders = encoders
    }

    /// Resolves a firmware definition into renderer geometry and legends.
    ///
    /// - Parameter firmware: The same type-erased definition consumed by generation.
    public init(firmware: AnyFirmware) {
        let layers = firmware.layers.map {
            KeymapRenderLayer(id: $0.id.rawValue, name: $0.name, showsHUD: $0.showsHUD)
        }
        let legendResolver = FirmwareLegendResolver(firmware: firmware)
        let keys = firmware.layout.keys.enumerated().map { index, placement in
            KeymapRenderKey(
                id: "r\(placement.matrixPosition.row)c\(placement.matrixPosition.column)",
                placement: placement.geometry,
                legends: firmware.layers.map { layer in
                    legendResolver.legend(for: layer.keys[index], layers: layers)
                }
            )
        }
        let encoders = firmware.layout.encoders.sorted(by: { $0.index < $1.index }).map { encoder in
            let firmwareEncoder = firmware.encoders.first { $0.index == encoder.index }
            let counterclockwise = firmware.layers.map { layer in
                let key = firmwareEncoder?.mappings.first { $0.layer == layer.id }?.counterclockwise
                return key.map { legendResolver.legend(for: $0, layers: layers) } ?? .empty
            }
            let clockwise = firmware.layers.map { layer in
                let key = firmwareEncoder?.mappings.first { $0.layer == layer.id }?.clockwise
                return key.map { legendResolver.legend(for: $0, layers: layers) } ?? .empty
            }
            let press = encoder.pressPosition.map { position in
                firmware.layers.map { layer -> KeymapRenderLegend in
                    guard let keyIndex = firmware.layout.keys.firstIndex(where: {
                        $0.matrixPosition == position
                    }) else { return .empty }
                    return legendResolver.legend(for: layer.keys[keyIndex], layers: layers)
                }
            } ?? Array(repeating: .empty, count: firmware.layers.count)
            return KeymapRenderEncoder(
                id: encoder.id,
                placement: encoder.geometry,
                counterclockwiseLegends: counterclockwise,
                pressLegends: press,
                clockwiseLegends: clockwise
            )
        }
        self.init(
            layoutID: firmware.layoutID,
            displayName: firmware.layout.displayName,
            canvasWidth: firmware.layout.canvasWidth,
            canvasHeight: firmware.layout.canvasHeight,
            layers: layers,
            keys: keys,
            encoders: encoders
        )
    }
}

fileprivate struct FirmwareLegendResolver {
    let firmware: AnyFirmware

    func legend(for key: AnyFirmwareKey, layers: [KeymapRenderLayer]) -> KeymapRenderLegend {
        let semantic = key.semanticID.flatMap { id in firmware.semantics.first { $0.id == id } }
        let style = firmware.styles.first { $0.id == key.styleID }
        let label =
            key.legend
            ?? semantic?.legend
            ?? HostLegend.label(for: key, layers: layers)
        return KeymapRenderLegend(
            label: label,
            symbolName: semantic?.symbolName,
            style: style.map {
                KeymapRenderStyle(
                    red: $0.color.red,
                    green: $0.color.green,
                    blue: $0.color.blue
                )
            } ?? .standard,
            isTransparent: key.keycode == 1
        )
    }
}

/// Produces compact host labels from QMK's numeric keycode ABI.
fileprivate enum HostLegend {
    /// Resolves a keycode into a glyph, a named action, or a hexadecimal fallback.
    static func label(for key: AnyFirmwareKey, layers: [KeymapRenderLayer]) -> String {
        let value = key.keycode
        if let label = basicLabel(for: value) { return label }

        let shiftedLabels: [UInt16: String] = [
            0x021E: "!", 0x021F: "@", 0x0220: "#", 0x0221: "$", 0x0222: "%",
            0x0223: "^", 0x0226: "(", 0x0227: ")", 0x022E: "+", 0x022F: "{",
            0x0230: "}", 0x0233: ":",
        ]
        if let label = shiftedLabels[value] { return label }

        if (value & 0xFFE0) == 0x5220 || (value & 0xFFE0) == 0x5260 {
            let layerID = UInt8(value & 0x1F)
            return layers.first { $0.id == layerID }?.name ?? "Layer \(layerID)"
        }

        if (value & 0xF000) == 0x4000 {
            let layerID = UInt8((value >> 8) & 0x0F)
            let layerName = layers.first { $0.id == layerID }?.name ?? "Layer \(layerID)"
            let tapLabel = basicLabel(for: value & 0x00FF) ?? hexadecimalLabel(for: value & 0x00FF)
            return "\(tapLabel) / \(layerName)"
        }

        if (value & 0xE000) == 0x2000 {
            let modifierMask = UInt8((value >> 8) & 0x1F)
            let tapLabel = basicLabel(for: value & 0x00FF) ?? hexadecimalLabel(for: value & 0x00FF)
            return "\(modifierSymbols(for: modifierMask)) / \(tapLabel)"
        }

        let modifierMask = UInt8(value >> 8)
        if (1...0x1F).contains(modifierMask), let baseLabel = basicLabel(for: value & 0x00FF) {
            return modifierSymbols(for: modifierMask) + baseLabel
        }

        return hexadecimalLabel(for: value)
    }

    /// Resolves unmodified HID and QMK keycodes used by the typed keymap API.
    static func basicLabel(for value: UInt16) -> String? {
        if value == 0 || value == 1 { return "" }
        if (0x0004...0x001D).contains(value) {
            return UnicodeScalar(Int(value - 0x0004) + 65).map(String.init) ?? ""
        }
        if (0x001E...0x0026).contains(value) { return String(Int(value - 0x001D)) }
        if value == 0x0027 { return "0" }
        if (0x003A...0x0045).contains(value) { return "F\(value - 0x0039)" }
        if (0x0068...0x0073).contains(value) { return "F\(value - 0x005B)" }

        let labels: [UInt16: String] = [
            0x0028: "Return", 0x0029: "Escape", 0x002A: "Delete", 0x002B: "Tab",
            0x002C: "Space", 0x002D: "−", 0x002E: "=", 0x002F: "[", 0x0030: "]",
            0x0031: "\\", 0x0033: ";", 0x0034: "'", 0x0035: "`", 0x0036: ",",
            0x0037: ".", 0x0038: "/", 0x0039: "⇪", 0x0046: "Print Screen",
            0x004C: "Forward Delete", 0x004F: "→", 0x0050: "←", 0x0051: "↓", 0x0052: "↑",
            0x007F: "Mute", 0x0080: "Volume +", 0x0081: "Volume −", 0x00A8: "Mute",
            0x00A9: "Volume +", 0x00AA: "Volume −", 0x00AB: "Next", 0x00AC: "Previous",
            0x00AE: "Play", 0x00E0: "⌃", 0x00E1: "⇧", 0x00E2: "⌥", 0x00E3: "⌘",
            0x00E4: "⌃", 0x00E5: "⇧", 0x00E6: "⌥", 0x00E7: "⌘",
            0x7842: "RGB", 0x7843: "RGB Next", 0x7844: "RGB Previous", 0x7845: "Hue +",
            0x7846: "Hue −", 0x7847: "Saturation +", 0x7848: "Saturation −",
            0x7849: "Brightness +", 0x784A: "Brightness −", 0x784B: "Speed +",
            0x784C: "Speed −", 0x7C00: "Boot",
        ]
        return labels[value]
    }

    /// Produces the familiar macOS keyboard symbols for a QMK modifier mask.
    static func modifierSymbols(for mask: UInt8) -> String {
        var symbols = ""
        if (mask & 0x01) != 0 { symbols += "⌃" }
        if (mask & 0x02) != 0 { symbols += "⇧" }
        if (mask & 0x04) != 0 { symbols += "⌥" }
        if (mask & 0x08) != 0 { symbols += "⌘" }
        return symbols
    }

    /// Formats an unknown numeric ABI value for debugging.
    static func hexadecimalLabel(for value: UInt16) -> String {
        let hexadecimal = String(value, radix: 16, uppercase: true)
        return "0x\(String(repeating: "0", count: 4 - hexadecimal.count))\(hexadecimal)"
    }
}

fileprivate extension KeymapRenderLegend {
    static let empty = KeymapRenderLegend(label: "")
}
