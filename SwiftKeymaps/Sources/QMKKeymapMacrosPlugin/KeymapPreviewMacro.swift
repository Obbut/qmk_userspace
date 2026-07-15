import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Expands `#KeymapPreview` into the production keymap renderer.
public struct KeymapPreviewMacro: ExpressionMacro {
    /// Expands one firmware preview expression.
    ///
    /// - Parameters:
    ///   - node: The source macro invocation.
    ///   - context: The compiler expansion context.
    /// - Returns: A production renderer expression for Apple's `#Preview` macro.
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard node.arguments.count == 1,
            let firmware = node.arguments.first?.expression
        else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: MacroDiagnostic(
                        "#KeymapPreview requires exactly one firmware type.",
                        id: "invalid-keymap-preview-arguments"
                    )
                )
            )
            return "fatalError(\"Invalid #KeymapPreview invocation\")"
        }
        return "QMKKeymapRenderer.KeymapPreviewView(\(firmware))"
    }
}
