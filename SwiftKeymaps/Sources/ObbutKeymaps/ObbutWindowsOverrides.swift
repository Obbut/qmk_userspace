import QMKFirmwareRuntime

/// Platform-aware screenshot and Command/Control behavior shared by Obbut keyboards.
public struct ObbutWindowsOverrides: FirmwareFeature, Sendable {
    /// Build metadata for operating-system overrides.
    public let firmwareFeatureDescriptor = FirmwareFeatureDescriptor(
        id: "obbut.windows-overrides",
        buildSettings: [.make(variable: "OS_DETECTION_ENABLE", value: "yes")]
    )

    /// Creates operating-system overrides.
    public init() {}
}
