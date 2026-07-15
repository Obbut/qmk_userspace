import QMKKeymapKit

/// A resolved key used by generated artifacts and host previews.
public struct AnyFirmwareKey: Equatable, Sendable {
    /// The QMK C expression.
    public let cExpression: String

    /// The optional basic HID value.
    public let hidValue: UInt16?

    /// The optional explicit legend.
    public let legend: String?

    /// The generated semantic wire identifier.
    public let semanticID: UInt16?

    /// The generated style wire identifier.
    public let styleID: UInt16

    /// Resolves one source key against automatically collected metadata.
    ///
    /// - Parameters:
    ///   - key: The source key to resolve.
    ///   - metadata: The metadata collected from the complete firmware.
    init(_ key: Key, metadata: GeneratedKeyMetadata) {
        cExpression = key.keycode.cExpression
        hidValue = key.keycode.hidValue
        legend = key.legend
        semanticID = metadata.semanticID(for: key)
        styleID = metadata.styleID(for: key)
    }
}
