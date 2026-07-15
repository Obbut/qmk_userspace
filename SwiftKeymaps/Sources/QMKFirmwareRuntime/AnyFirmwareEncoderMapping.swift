import QMKKeymapKit

/// A domain-erased encoder mapping for one layer.
public struct AnyFirmwareEncoderMapping: Sendable {
    /// The layer selecting this mapping.
    public let layer: LayerID

    /// The counterclockwise action.
    public let counterclockwise: AnyFirmwareKey

    /// The clockwise action.
    public let clockwise: AnyFirmwareKey

    /// Erases a domain-typed encoder mapping.
    ///
    /// - Parameter mapping: The mapping to erase.
    public init<Domain: KeymapDomain>(_ mapping: On<Domain>) {
        layer = mapping.layer
        counterclockwise = AnyFirmwareKey(mapping.counterclockwise)
        clockwise = AnyFirmwareKey(mapping.clockwise)
    }
}
