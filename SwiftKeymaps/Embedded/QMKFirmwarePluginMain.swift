import SwiftSyntaxMacros
@_spi(PluginMessage) private import SwiftCompilerPluginMessageHandling

/// Minimal toolchain-hosted entry point used by QMK's direct firmware build.
protocol QMKCompilerPlugin {
    init()
    var providingMacros: [Macro.Type] { get }
}

extension QMKCompilerPlugin {
    static func main() throws {
        let connection = try StandardIOMessageConnection()
        let provider = QMKMacroProvider(plugin: Self())
        let listener = CompilerPluginMessageListener(connection: connection, provider: provider)
        try listener.main()
    }
}

fileprivate struct QMKMacroProvider<Plugin: QMKCompilerPlugin>: PluginProvider {
    let plugin: Plugin

    func resolveMacro(moduleName: String, typeName: String) throws -> Macro.Type {
        let qualifiedName = "\(moduleName).\(typeName)"
        for type in plugin.providingMacros where String(reflecting: type) == qualifiedName {
            return type
        }
        throw QMKCompilerPluginError(description: "macro '\(qualifiedName)' was not found")
    }
}

fileprivate struct QMKCompilerPluginError: Error, CustomStringConvertible {
    let description: String
}

@main
struct QMKFirmwarePlugin: QMKCompilerPlugin {
    let providingMacros: [Macro.Type] = [QMKFirmwareMacro.self]
}
