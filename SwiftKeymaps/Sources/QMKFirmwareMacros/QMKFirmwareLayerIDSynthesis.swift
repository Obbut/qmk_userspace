import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension QMKFirmwareMacro {
    /// Synthesizes the firmware's nested layer namespace from inferred layer declarations.
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let firmware = declaration.as(EnumDeclSyntax.self),
            !hasLayerIDDeclaration(firmware)
        else {
            return []
        }

        let discovered = automaticLayers(in: firmware, context: context)
        guard discovered.isValid, !discovered.layers.isEmpty else { return [] }

        if discovered.layers.count > 32 {
            context.diagnose(
                Diagnostic(
                    node: discovered.layers[32].node,
                    message: QMKFirmwareDiagnostic(
                        "too-many-layers",
                        message: "QMK firmware supports at most 32 generated layers."
                    )
                )
            )
            return []
        }

        var seenCases: Set<String> = []
        var declarations: [String] = []
        for (ordinal, layer) in discovered.layers.enumerated() {
            guard seenCases.insert(layer.caseName).inserted else {
                context.diagnose(
                    Diagnostic(
                        node: layer.node,
                        message: QMKFirmwareDiagnostic(
                            "duplicate-layer-id",
                            message: "Layer names must produce unique LayerID cases; '\(layer.caseName)' is duplicated."
                        )
                    )
                )
                return []
            }
            declarations.append("case \(layer.caseName) = \(ordinal)")
        }

        let cases = declarations.joined(separator: "\n")
        let layerID: DeclSyntax = """
            public enum LayerID: UInt8, FirmwareLayerID {
            \(raw: cases)
            }
            """
        return [layerID]
    }
}

fileprivate extension QMKFirmwareMacro {
    static func hasLayerIDDeclaration(_ firmware: EnumDeclSyntax) -> Bool {
        firmware.memberBlock.members.contains { member in
            let declaration = member.decl
            return declaration.as(EnumDeclSyntax.self)?.name.text == "LayerID"
                || declaration.as(StructDeclSyntax.self)?.name.text == "LayerID"
                || declaration.as(ClassDeclSyntax.self)?.name.text == "LayerID"
                || declaration.as(ActorDeclSyntax.self)?.name.text == "LayerID"
                || declaration.as(ProtocolDeclSyntax.self)?.name.text == "LayerID"
                || declaration.as(TypeAliasDeclSyntax.self)?.name.text == "LayerID"
        }
    }

    static func automaticLayers(
        in firmware: EnumDeclSyntax,
        context: some MacroExpansionContext
    ) -> (layers: [(caseName: String, node: Syntax)], isValid: Bool) {
        guard let keymap = firmware.memberBlock.members.compactMap({ member in
            member.decl.as(VariableDeclSyntax.self)
        }).first(where: { variable in
            variable.bindings.contains { binding in
                binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "keymap"
            }
        }) else {
            return ([], true)
        }

        var layers: [(caseName: String, node: Syntax)] = []
        var isValid = true
        collectAutomaticLayers(
            in: Syntax(keymap),
            layers: &layers,
            isValid: &isValid,
            context: context
        )
        return (layers, isValid)
    }

    static func collectAutomaticLayers(
        in syntax: Syntax,
        layers: inout [(caseName: String, node: Syntax)],
        isValid: inout Bool,
        context: some MacroExpansionContext
    ) {
        if let call = syntax.as(FunctionCallExprSyntax.self),
            isLayerCall(call),
            call.arguments.first?.label?.text == "name",
            let nameArgument = call.arguments.first(where: { $0.label?.text == "name" })
        {
            guard let literal = nameArgument.expression.as(StringLiteralExprSyntax.self),
                literal.segments.count == 1,
                let segment = literal.segments.first?.as(StringSegmentSyntax.self),
                let caseName = layerCaseName(for: segment.content.text)
            else {
                context.diagnose(
                    Diagnostic(
                        node: Syntax(nameArgument.expression),
                        message: QMKFirmwareDiagnostic(
                            "invalid-generated-layer-name",
                            message: "A generated LayerID requires a nonempty static string literal name."
                        )
                    )
                )
                isValid = false
                return
            }
            layers.append((caseName, Syntax(nameArgument.expression)))
        }

        for child in syntax.children(viewMode: .sourceAccurate) {
            collectAutomaticLayers(
                in: child,
                layers: &layers,
                isValid: &isValid,
                context: context
            )
        }
    }

    static func isLayerCall(_ call: FunctionCallExprSyntax) -> Bool {
        if let reference = call.calledExpression.as(DeclReferenceExprSyntax.self) {
            return reference.baseName.text == "Layer"
        }
        if let member = call.calledExpression.as(MemberAccessExprSyntax.self) {
            return member.declName.baseName.text == "Layer"
        }
        return false
    }

    static func layerCaseName(for displayName: String) -> String? {
        let words = displayName.split { character in
            !character.isLetter && !character.isNumber
        }
        guard let first = words.first else { return nil }

        var identifier = lowercasingInitial(first)
        for word in words.dropFirst() {
            identifier += uppercasingInitial(word)
        }
        if identifier.first?.isNumber == true {
            identifier = "layer" + uppercasingInitial(identifier[...])
        }
        if swiftKeywords.contains(identifier) {
            identifier += "Layer"
        }
        return identifier
    }

    static func lowercasingInitial(_ word: Substring) -> String {
        if word.allSatisfy({ !$0.isLetter || $0.isUppercase }) {
            return word.lowercased()
        }
        guard let first = word.first else { return "" }
        return first.lowercased() + word.dropFirst()
    }

    static func uppercasingInitial(_ word: Substring) -> String {
        guard let first = word.first else { return "" }
        if word.allSatisfy({ !$0.isLetter || $0.isUppercase }) {
            return first.uppercased() + word.dropFirst().lowercased()
        }
        return first.uppercased() + word.dropFirst()
    }

    static let swiftKeywords: Set<String> = [
        "associatedtype", "break", "case", "catch", "class", "continue", "default",
        "defer", "deinit", "do", "else", "enum", "extension", "fallthrough", "false",
        "fileprivate", "for", "func", "guard", "if", "import", "in", "init", "inout",
        "internal", "is", "let", "nil", "operator", "precedencegroup", "private",
        "protocol", "public", "repeat", "rethrows", "return", "self", "Self", "static",
        "struct", "subscript", "super", "switch", "throw", "throws", "true", "try",
        "typealias", "var", "where", "while",
    ]
}
