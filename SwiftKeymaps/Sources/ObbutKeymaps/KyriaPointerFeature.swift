import QMKFirmwareRuntime

/// Stateful Cirque movement, scrolling, sniper, sensitivity, and drag-lock behavior.
public struct KyriaPointerFeature: FirmwareFeature, Sendable {
    public let firmwareFeatureDescriptor = FirmwareFeatureDescriptor(
        id: "obbut.kyria-pointer"
    )

    public init() {}
}
