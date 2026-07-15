import QMKFirmwareRuntime

/// Platform-aware screenshot and Command/Control behavior shared by Obbut keyboards.
public struct ObbutWindowsOverrides: FirmwareFeature, Sendable {
    public let firmwareFeatureDescriptor = FirmwareFeatureDescriptor(
        id: "obbut.windows-overrides",
        buildSettings: [.make(variable: "OS_DETECTION_ENABLE", value: "yes")]
    )

    public init() {}
}
