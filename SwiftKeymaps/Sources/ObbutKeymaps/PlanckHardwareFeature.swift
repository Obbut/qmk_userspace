import QMKFirmwareRuntime

/// Planck hardware LEDs and tri-layer behavior.
public struct PlanckHardwareFeature: FirmwareFeature, Sendable {
    public let firmwareFeatureDescriptor = FirmwareFeatureDescriptor(
        id: "obbut.planck-hardware"
    )

    public init() {}
}
