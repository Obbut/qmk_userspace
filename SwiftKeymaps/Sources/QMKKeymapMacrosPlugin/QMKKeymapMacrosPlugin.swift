#if !QMK_DIRECT_PLUGIN
import SwiftCompilerPlugin
#endif
import SwiftSyntaxMacros

/// The compiler-plugin entry point for Swift-first QMK source macros.
@main
struct QMKKeymapMacrosPlugin: CompilerPlugin {
    /// The macro implementations exposed by this plugin executable.
    let providingMacros: [Macro.Type] = [
        KeymapMacro.self,
        KeymapPreviewMacro.self,
        QMKKeycodeMacro.self,
        QMKBridgeMacro.self,
    ]
}
