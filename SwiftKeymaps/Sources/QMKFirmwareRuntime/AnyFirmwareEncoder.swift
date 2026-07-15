import QMKKeymapKit

/// A domain-erased encoder used by generated artifacts and host previews.
public struct AnyFirmwareEncoder: Sendable {
    /// The zero-based QMK encoder index.
    public let index: Int

    /// The stable encoder identifier.
    public let id: String

    /// The layer-specific action pairs.
    public let mappings: [AnyFirmwareEncoderMapping]

    /// Erases a domain-typed encoder.
    ///
    /// - Parameter encoder: The encoder to erase.
    public init<Domain: KeymapDomain>(_ encoder: Encoder<Domain>) {
        index = encoder.index
        id = encoder.id
        mappings = encoder.mappings.map(AnyFirmwareEncoderMapping.init)
    }
}
