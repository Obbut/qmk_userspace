import Foundation
import ObbutKeyboardCatalog

/// The command-line entry point for generating QMK ABI artifacts from Swift.
@main
struct KeymapCompiler {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let target = value(after: "--keyboard", in: arguments) ?? "all"
        let outputRoot = value(after: "--output-root", in: arguments) ?? FileManager.default.currentDirectoryPath
        let firmwares = try selectedFirmware(named: target)
        let writer = ArtifactWriter(repositoryRoot: URL(filePath: outputRoot, directoryHint: .isDirectory))

        for firmware in firmwares {
            try writer.write(CEmitter(firmware: firmware).artifacts(), for: firmware)
            print("Generated \(firmware.id)")
        }
    }

    private static func value(after option: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: option), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }

    private static func selectedFirmware(named target: String) throws -> [QMKFirmwareRuntime.AnyFirmware] {
        if target == "all" { return ObbutKeyboardCatalog.all }
        guard let firmware = ObbutKeyboardCatalog.firmware(named: target) else {
            throw CompilerError.unknownFirmware(target)
        }
        return [firmware]
    }
}

import QMKFirmwareRuntime

/// Command-line failures reported by the keymap compiler.
private enum CompilerError: Error, CustomStringConvertible {
    case unknownFirmware(String)

    var description: String {
        switch self {
        case let .unknownFirmware(identifier):
            "Unknown firmware '\(identifier)'. Use kyria, elora, q15, planck, or all."
        }
    }
}
