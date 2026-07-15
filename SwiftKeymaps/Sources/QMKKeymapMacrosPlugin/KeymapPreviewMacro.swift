import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Expands `#KeymapPreview` into an Xcode `#Preview` declaration.
public struct KeymapPreviewMacro: DeclarationMacro {
    /// Expands one firmware preview declaration.
    ///
    /// - Parameters:
    ///   - node: The source macro invocation.
    ///   - context: The compiler expansion context.
    /// - Returns: One Xcode preview provider using the production renderer.
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
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
            return []
        }
        return [
            """
            @MainActor
            private struct __KeymapPreview: SwiftUI.PreviewProvider {
                static var previews: some SwiftUI.View {
                    QMKKeymapRenderer.KeymapPreviewView(\(firmware))
                }
            }
            """
        ]
    }
}
