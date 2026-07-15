import QMKKeymapKit

/// A domain-erased key used by generated artifacts and host previews.
public struct AnyFirmwareKey: Equatable, Sendable {
    /// The QMK C expression.
    public let cExpression: String

    /// The optional basic HID value.
    public let hidValue: UInt16?

    /// The optional explicit legend.
    public let legend: String?

    /// The catalog-scoped semantic identifier.
    public let semanticID: UInt16?

    /// The catalog-scoped visual-style identifier.
    public let styleID: UInt16?

    /// Erases a domain-typed key.
    ///
    /// - Parameter key: The key to erase.
    public init<Domain: KeymapDomain>(_ key: Key<Domain>) {
        cExpression = key.keycode.cExpression
        hidValue = key.keycode.hidValue
        legend = key.legend
        semanticID = key.semanticID?.rawValue
        styleID = key.styleID?.rawValue
    }
}
