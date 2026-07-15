import QMKFirmwareRuntime

/// Planck hardware LEDs and tri-layer behavior.
public struct PlanckHardwareFeature: FirmwareFeature, Sendable {
    /// Build metadata for Planck hardware integration.
    public let firmwareFeatureDescriptor = FirmwareFeatureDescriptor(
        id: "obbut.planck-hardware"
    )

    /// Creates Planck hardware integration.
    public init() {}
}
