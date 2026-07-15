import QMKFirmwareRuntime
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
            isTransparent: key.hidValue == 1 || key.cExpression == "KC_TRNS"
        )
    }
}

fileprivate enum HostLegend {
    static func label(for key: AnyFirmwareKey, layers: [KeymapRenderLayer]) -> String {
        if let value = key.hidValue {
            if value == 0 || value == 1 { return "" }
            if (0x0004...0x001D).contains(value) {
                return UnicodeScalar(Int(value - 0x0004) + 65).map(String.init) ?? ""
            }
            if (0x001E...0x0026).contains(value) { return String(Int(value - 0x001D)) }
            if value == 0x0027 { return "0" }
            let labels: [UInt16: String] = [
                0x0028: "Return", 0x0029: "Escape", 0x002A: "Delete", 0x002B: "Tab",
                0x002C: "Space", 0x004C: "Forward Delete", 0x004F: "→", 0x0050: "←",
                0x0051: "↓", 0x0052: "↑", 0x007F: "Mute", 0x0080: "Volume +",
                0x0081: "Volume −", 0x00AB: "Next", 0x00AC: "Previous", 0x00AE: "Play",
                0x7842: "RGB", 0x7843: "Next", 0x7844: "Previous", 0x7C00: "Boot",
            ]
            if let label = labels[value] { return label }
            if (value & 0xFFE0) == 0x5220 {
                let layerID = UInt8(value & 0x1F)
                return layers.first { $0.id == layerID }?.name ?? "Layer \(layerID)"
            }
        }
        return key.cExpression
            .replacingOccurrences(of: "KC_", with: "")
            .replacingOccurrences(of: "_", with: " ")
    }
}

fileprivate extension KeymapRenderLegend {
    static let empty = KeymapRenderLegend(label: "")
}
