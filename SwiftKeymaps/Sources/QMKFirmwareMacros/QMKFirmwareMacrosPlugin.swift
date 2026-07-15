import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// Compiler-plugin entry point for the firmware declaration macro.
@main
struct QMKFirmwareMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [QMKFirmwareMacro.self]
}
