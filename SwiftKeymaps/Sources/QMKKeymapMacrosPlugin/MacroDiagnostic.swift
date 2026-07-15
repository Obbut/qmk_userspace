import SwiftDiagnostics

/// A concise compiler diagnostic emitted by a keymap macro.
struct MacroDiagnostic: DiagnosticMessage {
    /// The human-readable diagnostic text.
    let message: String

    /// The stable diagnostic identifier.
    let diagnosticID: MessageID

    /// The diagnostic severity.
    let severity: DiagnosticSeverity

    /// Creates an error diagnostic.
    ///
    /// - Parameters:
    ///   - message: The human-readable diagnostic text.
    ///   - id: The stable identifier within the keymap macro domain.
    init(_ message: String, id: String) {
        self.message = message
        diagnosticID = MessageID(domain: "SwiftQMKKeymaps", id: id)
        severity = .error
    }
}
