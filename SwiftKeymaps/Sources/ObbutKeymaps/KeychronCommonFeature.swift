import QMKFirmwareRuntime

/// Delegation to Keychron's required common key-processing hook.
public struct KeychronCommonFeature: FirmwareFeature, Sendable {
    public let firmwareFeatureDescriptor = FirmwareFeatureDescriptor(
        id: "obbut.keychron-common"
    )

    public init() {}
}
