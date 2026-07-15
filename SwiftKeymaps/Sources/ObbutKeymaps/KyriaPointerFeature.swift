import QMKFirmwareRuntime

/// Stateful Cirque movement, scrolling, sniper, sensitivity, and drag-lock behavior.
public struct KyriaPointerFeature: FirmwareFeature, Sendable {
    /// Build metadata for the complete Kyria pointer engine.
    public let firmwareFeatureDescriptor = FirmwareFeatureDescriptor(
        id: "obbut.kyria-pointer"
    )

    /// Creates the complete Kyria pointer engine.
    public init() {}
}
