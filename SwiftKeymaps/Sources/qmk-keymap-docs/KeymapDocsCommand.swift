import Foundation
import ObbutKeyboardCatalog
import QMKFirmwareHost

/// Emits keymap-drawer YAML from the same typed firmware declarations that QMK compiles.
@main
struct KeymapDocsCommand {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let requestedFirmware = value(after: "--keyboard", in: arguments) ?? "all"
        let outputRoot = value(after: "--output-root", in: arguments)
            ?? FileManager.default.currentDirectoryPath
        let firmwares: [AnyFirmware]

        if requestedFirmware == "all" {
            firmwares = ObbutKeyboardCatalog.all
        } else if let firmware = ObbutKeyboardCatalog.firmware(named: requestedFirmware) {
            firmwares = [firmware]
        } else {
            throw KeymapDocsError.unknownFirmware(requestedFirmware)
        }

        let root = URL(filePath: outputRoot, directoryHint: .isDirectory)
        for firmware in firmwares {
            let output = root.appending(path: "keymap-\(shortName(for: firmware)).yaml")
            try Data(KeymapDrawerEmitter(firmware: firmware).yaml().utf8)
                .write(to: output, options: .atomic)
            print("Wrote \(output.path)")
        }
    }

    private static func value(after option: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: option),
            arguments.indices.contains(index + 1)
        else {
            return nil
        }
        return arguments[index + 1]
    }

    private static func shortName(for firmware: AnyFirmware) -> String {
        switch firmware.id {
        case "com.obbut.kyria-rev4": "kyria"
        case "com.obbut.elora-rev2": "elora"
        case "com.obbut.keychron-q15-max": "q15"
        case "com.obbut.planck-ez-glow": "planck"
        default: preconditionFailure("No documentation name is registered for \(firmware.id).")
        }
    }
}

private enum KeymapDocsError: Error, CustomStringConvertible {
    case unknownFirmware(String)

    var description: String {
        switch self {
        case let .unknownFirmware(identifier):
            "Unknown firmware '\(identifier)'. Use kyria, elora, q15, planck, or all."
        }
    }
}
