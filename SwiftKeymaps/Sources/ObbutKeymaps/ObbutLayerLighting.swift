import QMKFirmwareRuntime

/// Style-driven RGB layer lighting shared by Obbut keyboards.
public struct ObbutLayerLighting: FirmwareFeature, Sendable {
    public let firmwareFeatureDescriptor = FirmwareFeatureDescriptor(
        id: "obbut.layer-lighting"
    )

    public init() {}
}
