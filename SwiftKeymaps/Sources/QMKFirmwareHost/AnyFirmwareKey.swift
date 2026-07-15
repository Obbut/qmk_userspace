import QMKKeymapKit

/// A resolved key used by host documentation and previews.
public struct AnyFirmwareKey: Equatable, Sendable {
    /// The exact QMK ABI value.
    public let keycode: UInt16

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
        keycode = key.keycode.rawValue
        legend = key.legend.map(StaticStringContent.string)
        semanticID = metadata.semanticID(for: key)
        styleID = metadata.styleID(for: key)
    }
}
