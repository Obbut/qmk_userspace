import Foundation
import QMKFirmwareHost

/// Emits documentation YAML without producing any firmware input.
struct KeymapDrawerEmitter {
    let firmware: AnyFirmware

    func yaml() -> String {
        let layers = firmware.layers.map { layer in
            let entries = layer.keys.map(yamlEntry).joined(separator: ", ")
            return "  \(quoted(layer.name)):\n    [\(entries)]"
        }
        return """
        # Generated for documentation by qmk-keymap-docs. Firmware does not consume this file.
        layout:
          qmk_info_json: \(layoutJSONName)
          layout_name: \(firmware.layout.cMacro)

        layers:
        \(layers.joined(separator: "\n"))
        """
    }

    private var layoutJSONName: String {
        switch firmware.id {
        case "com.obbut.kyria-rev4": "kyria-layout.json"
        case "com.obbut.elora-rev2": "elora-layout.json"
        case "com.obbut.keychron-q15-max": "q15-layout.json"
        case "com.obbut.planck-ez-glow": "planck-layout.json"
        default: preconditionFailure("No documentation layout is registered for \(firmware.id).")
        }
    }

    private func yamlEntry(for key: AnyFirmwareKey) -> String {
        let legend =
            key.legend
            ?? fallbackLegend(for: key.keycode)
        guard let styleName = styleName(for: key.styleID) else { return quoted(legend) }
        return "{t: \(quoted(legend)), type: \(quoted(styleName))}"
    }

    private func styleName(for styleID: UInt16) -> String? {
        guard let color = firmware.styles.first(where: { $0.id == styleID })?.color else {
            return nil
        }
        return switch (color.red, color.green, color.blue) {
        case (148, 0, 211): "rgb-purple"
        case (255, 0, 255): "rgb-magenta"
        case (0, 0, 255): "rgb-blue"
        case (255, 255, 0): "rgb-yellow"
        case (0, 255, 255), (0, 220, 220), (0, 180, 220): "rgb-cyan"
        case (0, 255, 0): "rgb-green"
        case (0, 50, 0): "rgb-green-dark"
        case (255, 128, 0): "rgb-orange"
        case (255, 0, 0), (255, 68, 68): "rgb-red"
        default: nil
        }
    }

    private func fallbackLegend(for keycode: UInt16) -> String {
        if keycode == 0 || keycode == 1 { return "" }
        if (0x0004...0x001D).contains(keycode) {
            return UnicodeScalar(Int(keycode - 0x0004) + 65).map(String.init) ?? ""
        }
        if (0x001E...0x0026).contains(keycode) { return String(Int(keycode - 0x001D)) }
        if keycode == 0x0027 { return "0" }
        return String(format: "0x%04X", keycode)
    }

    private func quoted(_ value: String) -> String {
        guard let data = try? JSONSerialization.data(
            withJSONObject: value,
            options: .fragmentsAllowed
        ), let encoded = String(data: data, encoding: .utf8) else {
            preconditionFailure("UTF-8 legends must be encodable.")
        }
        return encoded
    }
}
