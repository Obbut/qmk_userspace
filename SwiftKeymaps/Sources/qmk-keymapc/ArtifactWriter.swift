import Foundation
import QMKFirmwareRuntime

/// Writes generated QMK artifacts to the userspace overlay.
struct ArtifactWriter {
    let repositoryRoot: URL

    /// Writes one firmware's generated files atomically.
    ///
    /// - Parameters:
    ///   - artifacts: The generated artifact contents.
    ///   - firmware: The firmware selecting the keymap directory.
    func write(_ artifacts: GeneratedArtifacts, for firmware: AnyFirmware) throws {
        let directory = repositoryRoot.appending(path: relativeDirectory(for: firmware))
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try write(artifacts.keymapC, to: directory.appending(path: "keymap.c"))
        try write(artifacts.configH, to: directory.appending(path: "config.h"))
        try write(artifacts.rulesMK, to: directory.appending(path: "rules.mk"))
        try write(artifacts.metadataH, to: directory.appending(path: "keymap.generated.h"))
        try write(
            artifacts.keymapDrawerYAML,
            to: repositoryRoot.appending(path: "keymap-\(shortName(for: firmware)).yaml")
        )
    }

    private func relativeDirectory(for firmware: AnyFirmware) -> String {
        switch firmware.id {
        case "com.obbut.kyria-rev4":
            "keyboards/splitkb/halcyon/kyria/keymaps/obbut"
        case "com.obbut.elora-rev2":
            "keyboards/splitkb/halcyon/elora/keymaps/obbut"
        case "com.obbut.keychron-q15-max":
            "keyboards/keychron/q15_max/ansi_encoder/keymaps/obbut"
        case "com.obbut.planck-ez-glow":
            "keyboards/zsa/planck_ez/glow/keymaps/obbut"
        default:
            preconditionFailure("No QMK output directory is registered for \(firmware.id).")
        }
    }

    private func shortName(for firmware: AnyFirmware) -> String {
        switch firmware.id {
        case "com.obbut.kyria-rev4": "kyria"
        case "com.obbut.elora-rev2": "elora"
        case "com.obbut.keychron-q15-max": "q15"
        case "com.obbut.planck-ez-glow": "planck"
        default: preconditionFailure("No documentation name is registered for \(firmware.id).")
        }
    }

    private func write(_ contents: String, to url: URL) throws {
        try Data(contents.utf8).write(to: url, options: .atomic)
    }
}
