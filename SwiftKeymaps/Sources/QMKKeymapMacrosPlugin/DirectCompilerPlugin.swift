#if QMK_DIRECT_PLUGIN
import SwiftSyntaxMacros
@_spi(PluginMessage) import SwiftCompilerPluginMessageHandling

/// Minimal compiler-plugin entry point used by the direct Make build.
///
/// SwiftPM normally supplies this protocol through its `SwiftCompilerPlugin`
/// product. The Swift toolchain already ships the underlying message transport,
/// so the firmware build can host macros without resolving a package graph.
public protocol CompilerPlugin {
    /// Creates the compiler plugin.
    init()

    /// Macro implementation types provided by this executable.
    var providingMacros: [Macro.Type] { get }
}

/// Resolves macros exposed by a directly built compiler plugin.
fileprivate struct DirectMacroProvider<Plugin: CompilerPlugin>: PluginProvider {
    /// The concrete plugin instance.
    let plugin: Plugin

    /// Resolves one fully qualified macro implementation.
    func resolveMacro(moduleName: String, typeName: String) throws -> Macro.Type {
        let requestedName = "\(moduleName).\(typeName)"
        if let macro = plugin.providingMacros.first(where: {
            String(reflecting: $0) == requestedName
        }) {
            return macro
        }
        throw DirectCompilerPluginError(
            description: "Macro implementation '\(requestedName)' is not provided by this plugin."
        )
    }
}

/// Failure reported when the compiler asks for an unknown macro.
fileprivate struct DirectCompilerPluginError: Error, CustomStringConvertible {
    /// Human-readable compiler-plugin failure.
    let description: String
}

extension CompilerPlugin {
    /// Runs the standard compiler-plugin message loop.
    public static func main() throws {
        let connection = try StandardIOMessageConnection()
        let listener = CompilerPluginMessageListener(
            connection: connection,
            provider: DirectMacroProvider(plugin: Self())
        )
        try listener.main()
    }
}
#endif
