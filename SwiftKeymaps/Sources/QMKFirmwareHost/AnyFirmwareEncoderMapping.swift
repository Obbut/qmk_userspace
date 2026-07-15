import QMKKeymapKit

/// A resolved encoder mapping for one layer.
public struct AnyFirmwareEncoderMapping: Sendable {
    /// The layer selecting this mapping.
    public let layer: LayerID

    /// The counterclockwise action.
    public let counterclockwise: AnyFirmwareKey

    /// The clockwise action.
    public let clockwise: AnyFirmwareKey

    /// Resolves one mapping against automatically collected metadata.
    ///
    /// - Parameters:
    ///   - mapping: The source mapping to resolve.
    ///   - metadata: The metadata collected from the complete firmware.
    init(_ mapping: On, metadata: GeneratedKeyMetadata) {
        layer = mapping.layer
        counterclockwise = AnyFirmwareKey(mapping.counterclockwise, metadata: metadata)
        clockwise = AnyFirmwareKey(mapping.clockwise, metadata: metadata)
    }
}
