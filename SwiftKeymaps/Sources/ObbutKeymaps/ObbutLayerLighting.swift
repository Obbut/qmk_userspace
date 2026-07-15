import QMKFirmwareRuntime

/// Style-catalog-driven RGB layer lighting shared by Obbut keyboards.
public struct ObbutLayerLighting: FirmwareFeature, Sendable {
    /// Build metadata for layer lighting.
    public let firmwareFeatureDescriptor = FirmwareFeatureDescriptor(
        id: "obbut.layer-lighting"
    )

    /// Creates style-catalog-driven layer lighting.
    public init() {}
}
