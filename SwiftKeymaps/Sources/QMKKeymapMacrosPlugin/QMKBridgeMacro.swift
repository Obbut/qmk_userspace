import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Expands `#qmkBridge` into safe callback and symbol descriptors.
public struct QMKBridgeMacro: ExpressionMacro {
    /// Expands one custom Embedded Swift bridge.
    ///
    /// - Parameters:
    ///   - node: The source macro invocation.
    ///   - context: The compiler expansion context.
    /// - Returns: A `QMKBridgeFeature` construction expression.
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let identifier = node.arguments.first(where: { $0.label?.text == "id" })?.expression else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: MacroDiagnostic("#qmkBridge requires a stable id.", id: "missing-bridge-id")
                )
            )
            return "QMKBridgeFeature(id: \"invalid\", hooks: [])"
        }

        let supported = Set([
            "keyboardPostInit",
            "housekeeping",
            "processRecord",
            "layerStateSet",
            "pointingDeviceInit",
            "pointingDeviceTask",
            "rgbMatrixIndicatorsAdvanced",
            "rawHIDReceive",
        ])
        let hooks = node.arguments.compactMap { argument -> String? in
            guard let label = argument.label?.text, supported.contains(label) else { return nil }
            let token = argument.expression.trimmedDescription
            guard token != "nil" else { return nil }
            return ".init(callback: .\(label), symbol: \(token).spelling)"
        }
        return "QMKBridgeFeature(id: \(identifier), hooks: [\(raw: hooks.joined(separator: ", "))])"
    }
}
