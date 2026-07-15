import QMKFirmwareRuntime

/// Split visual-state synchronization for Halcyon keyboards.
public struct ObbutSplitSynchronization: FirmwareFeature, Sendable {
    public let firmwareFeatureDescriptor = FirmwareFeatureDescriptor(
        id: "obbut.split-synchronization"
    )

    public init() {}
}
