import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Adds the public firmware conformance and result-builder attributes.
public struct QMKFirmwareMacro: ExtensionMacro, MemberAttributeMacro, MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let firmware = declaration.as(EnumDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(declaration),
                    message: QMKFirmwareDiagnostic(
                        "requires-enum",
                        message: "@QMKFirmware can only be applied to an enum."
                    )
                )
            )
            return []
        }

        if explicitlyConformsToQMKFirmware(firmware) {
            context.diagnose(
                Diagnostic(
                    node: Syntax(firmware.name),
                    message: QMKFirmwareDiagnostic(
                        "redundant-conformance",
                        message: "Remove the explicit QMKFirmware conformance; @QMKFirmware adds it."
                    )
                )
            )
            return []
        }

        validateRequiredMembers(of: firmware, in: context)
        return [try ExtensionDeclSyntax("extension \(type.trimmed): QMKFirmware {}")]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard let firmware = declaration.as(EnumDeclSyntax.self),
            !explicitlyConformsToQMKFirmware(firmware)
        else {
            return []
        }
        guard let variable = member.as(VariableDeclSyntax.self) else {
            return []
        }

        if variable.isNamed("keymap"), variable.isStatic,
            !variable.hasAttribute(named: "Keymap")
        {
            return [
                AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: "_alwaysEmitIntoClient")
                ),
                AttributeSyntax(attributeName: IdentifierTypeSyntax(name: "Keymap")),
            ]
        }
        if variable.isNamed("features"), variable.isStatic,
            !variable.hasAttribute(named: "FirmwareFeatureBuilder")
        {
            return [
                AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: "_alwaysEmitIntoClient")
                ),
                AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: "FirmwareFeatureBuilder")
                ),
            ]
        }
        return []
    }

    private static func explicitlyConformsToQMKFirmware(_ firmware: EnumDeclSyntax) -> Bool {
        firmware.inheritanceClause?.inheritedTypes.contains { inheritedType in
            let name = inheritedType.type.trimmedDescription
            return name == "QMKFirmware" || name.hasSuffix(".QMKFirmware")
        } ?? false
    }

    private static func validateRequiredMembers(
        of firmware: EnumDeclSyntax,
        in context: some MacroExpansionContext
    ) {
        let variables = firmware.memberBlock.members.compactMap {
            $0.decl.as(VariableDeclSyntax.self)
        }
        let keymaps = variables.filter { $0.isNamed("keymap") }

        if keymaps.isEmpty {
            diagnoseMissing("keymap", on: firmware, in: context)
        } else if keymaps.count > 1 {
            context.diagnose(
                Diagnostic(
                    node: Syntax(keymaps[1]),
                    message: QMKFirmwareDiagnostic(
                        "duplicate-keymap",
                        message: "A firmware must declare exactly one static keymap property."
                    )
                )
            )
        } else if !keymaps[0].isStatic {
            context.diagnose(
                Diagnostic(
                    node: Syntax(keymaps[0]),
                    message: QMKFirmwareDiagnostic(
                        "nonstatic-keymap",
                        message: "The firmware keymap property must be static."
                    )
                )
            )
        } else if keymaps[0].hasAttribute(named: "Keymap") {
            context.diagnose(
                Diagnostic(
                    node: Syntax(keymaps[0]),
                    message: QMKFirmwareDiagnostic(
                        "redundant-keymap-attribute",
                        message: "Remove @Keymap; @QMKFirmware applies it automatically."
                    )
                )
            )
        }

        for name in ["id", "layout", "outputName", "features"] {
            guard let variable = variables.first(where: { $0.isNamed(name) }) else {
                diagnoseMissing(name, on: firmware, in: context)
                continue
            }
            if !variable.isStatic {
                context.diagnose(
                    Diagnostic(
                        node: Syntax(variable),
                        message: QMKFirmwareDiagnostic(
                            "nonstatic-\(name)",
                            message: "The firmware \(name) property must be static."
                        )
                    )
                )
            }
        }
    }

    private static func diagnoseMissing(
        _ memberName: String,
        on firmware: EnumDeclSyntax,
        in context: some MacroExpansionContext
    ) {
        context.diagnose(
            Diagnostic(
                node: Syntax(firmware.name),
                message: QMKFirmwareDiagnostic(
                    "missing-\(memberName)",
                    message: "@QMKFirmware requires a static \(memberName) property."
                )
            )
        )
    }
}

fileprivate extension VariableDeclSyntax {
    var isStatic: Bool {
        modifiers.contains { $0.name.tokenKind == .keyword(.static) }
    }

    func isNamed(_ expectedName: String) -> Bool {
        bindings.contains { binding in
            binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == expectedName
        }
    }

    func hasAttribute(named expectedName: String) -> Bool {
        attributes.contains { element in
            element.as(AttributeSyntax.self)?.attributeName.trimmedDescription == expectedName
        }
    }
}
