import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Expands `#Keymap` into the framework's validated result-builder initializer.
public struct KeymapMacro: ExpressionMacro {
    /// Expands one keymap expression.
    ///
    /// - Parameters:
    ///   - node: The source macro invocation.
    ///   - context: The compiler expansion context.
    /// - Returns: A `KeymapSpec` initializer expression.
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard node.arguments.count == 2,
            let trailingClosure = node.trailingClosure
        else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: MacroDiagnostic(
                        "#Keymap requires id, layout, and a trailing keymap closure.",
                        id: "invalid-keymap-arguments"
                    )
                )
            )
            return "KeymapSpec(id: \"invalid\", layout: .invalid) {}"
        }

        let arguments = Array(node.arguments)
        let identifier = arguments[0].expression
        let layout = arguments[1].expression
        return "KeymapSpec(id: \(identifier), layout: \(layout)) \(trailingClosure)"
    }
}
