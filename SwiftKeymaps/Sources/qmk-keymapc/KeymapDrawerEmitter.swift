import Foundation
import QMKFirmwareRuntime

/// Emits documentation YAML from the same firmware definitions as generated C.
struct KeymapDrawerEmitter {
    /// The authored firmware to document.
    let firmware: AnyFirmware

    /// Creates a complete keymap-drawer document.
    func yaml() -> String {
        let layers = firmware.layers.map { layer in
            let entries = layer.keys.map(yamlEntry).joined(separator: ", ")
            return "  \(quoted(layer.name)):\n    [\(entries)]"
        }
        return """
        # Generated from Swift by qmk-keymapc. Do not edit.
        layout:
          qmk_info_json: \(layoutJSONName)
          layout_name: \(firmware.layout.cMacro)

        layers:
        \(layers.joined(separator: "\n"))
        """
    }

    /// The repository-local QMK layout description used by keymap-drawer.
    private var layoutJSONName: String {
        switch firmware.id {
        case "com.obbut.kyria-rev4": "kyria-layout.json"
        case "com.obbut.elora-rev2": "elora-layout.json"
        case "com.obbut.keychron-q15-max": "q15-layout.json"
        case "com.obbut.planck-ez-glow": "planck-layout.json"
        default: preconditionFailure("No documentation layout is registered for \(firmware.id).")
        }
    }

    /// Creates one scalar or styled key entry.
    private func yamlEntry(for key: AnyFirmwareKey) -> String {
        let legend = key.legend
            ?? key.semanticID.flatMap { id in firmware.semantics.first { $0.id == id }?.legend }
            ?? fallbackLegend(for: key)
        guard let styleName = styleName(for: key.styleID) else { return quoted(legend) }
        return "{t: \(quoted(legend)), type: \(quoted(styleName))}"
    }

    /// Maps domain style IDs to the documentation stylesheet.
    private func styleName(for styleID: UInt16?) -> String? {
        switch styleID {
        case 1: "rgb-purple"
        case 2: "rgb-magenta"
        case 3: "rgb-blue"
        case 4: "rgb-yellow"
        case 5, 10, 11: "rgb-cyan"
        case 6: "rgb-green"
        case 7: "rgb-green-dark"
        case 8: "rgb-orange"
        case 9: "rgb-red"
        default: nil
        }
    }

    /// Creates a readable legend for a standard QMK expression.
    private func fallbackLegend(for key: AnyFirmwareKey) -> String {
        if key.cExpression == "KC_NO" || key.cExpression == "KC_TRNS" { return "" }
        return key.cExpression
            .replacingOccurrences(of: "KC_", with: "")
            .replacingOccurrences(of: "QK_", with: "")
            .replacingOccurrences(of: "_", with: " ")
    }

    /// Quotes arbitrary text using JSON's YAML-compatible string encoding.
    private func quoted(_ value: String) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed),
            let encoded = String(data: data, encoding: .utf8)
        else {
            preconditionFailure("UTF-8 legends must be encodable.")
        }
        return encoded
    }
}
