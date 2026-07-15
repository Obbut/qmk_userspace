import SwiftDiagnostics

/// A focused declaration diagnostic emitted by ``QMKFirmwareMacro``.
struct QMKFirmwareDiagnostic: DiagnosticMessage {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity = .error

    init(_ identifier: String, message: String) {
        self.message = message
        diagnosticID = MessageID(domain: "QMKFirmwareMacro", id: identifier)
    }
}
