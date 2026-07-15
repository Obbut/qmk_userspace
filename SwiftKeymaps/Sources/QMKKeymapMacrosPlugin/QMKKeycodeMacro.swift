import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Expands `#qmkKeycode` while preserving its QMK token as source text.
public struct QMKKeycodeMacro: ExpressionMacro {
    /// Expands one custom keycode expression.
    ///
    /// - Parameters:
    ///   - node: The source macro invocation.
    ///   - context: The compiler expansion context.
    /// - Returns: A domain-typed `Key.qmk` call.
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let token = node.arguments.first?.expression else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: MacroDiagnostic(
                        "#qmkKeycode requires a QMK token as its first argument.",
                        id: "missing-qmk-token"
                    )
                )
            )
            return "Key.qmk(\"KC_NO\")"
        }

        let expression = token.trimmedDescription
        let literal = StringLiteralExprSyntax(content: expression)
        let remaining = node.arguments.dropFirst().compactMap { argument -> String? in
            guard let label = argument.label?.text else { return nil }
            return "\(label): \(argument.expression.trimmedDescription)"
        }.joined(separator: ", ")
        if remaining.isEmpty {
            return "Key.qmk(\(literal))"
        }
        return "Key.qmk(\(literal), \(raw: remaining))"
    }
}
