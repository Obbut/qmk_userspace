import QMKFirmwareRuntime

/// Split visual-state synchronization for Halcyon keyboards.
public struct ObbutSplitSynchronization: FirmwareFeature, Sendable {
    /// Build metadata for split state synchronization.
    public let firmwareFeatureDescriptor = FirmwareFeatureDescriptor(
        id: "obbut.split-synchronization"
    )

    /// Creates split visual-state synchronization.
    public init() {}
}
