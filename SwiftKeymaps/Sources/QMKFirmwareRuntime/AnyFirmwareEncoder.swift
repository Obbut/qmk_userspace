import QMKKeymapKit

/// A resolved encoder used by generated artifacts and host previews.
public struct AnyFirmwareEncoder: Sendable {
    /// The zero-based QMK encoder index.
    public let index: Int

    /// The stable encoder identifier.
    public let id: String

    /// The layer-specific action pairs.
    public let mappings: [AnyFirmwareEncoderMapping]

    /// Resolves one encoder against automatically collected metadata.
    ///
    /// - Parameters:
    ///   - encoder: The source encoder to resolve.
    ///   - metadata: The metadata collected from the complete firmware.
    init(_ encoder: Encoder, metadata: GeneratedKeyMetadata) {
        index = encoder.index
        id = encoder.id
        mappings = encoder.mappings.map { AnyFirmwareEncoderMapping($0, metadata: metadata) }
    }
}
