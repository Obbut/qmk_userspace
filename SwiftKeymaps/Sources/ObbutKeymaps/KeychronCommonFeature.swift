import QMKFirmwareRuntime

/// Delegation to Keychron's required common key-processing hook.
public struct KeychronCommonFeature: FirmwareFeature, Sendable {
    /// Build metadata for Keychron callback delegation.
    public let firmwareFeatureDescriptor = FirmwareFeatureDescriptor(
        id: "obbut.keychron-common"
    )

    /// Creates Keychron common delegation.
    public init() {}
}
