import QMKFirmwareRuntime

/// Protocol-v4-only Keymap Companion firmware support.
public struct ObbutKeymapCompanion: FirmwareFeature, Sendable {
    public let firmwareFeatureDescriptor = FirmwareFeatureDescriptor(
        id: "obbut.keymap-companion-v4",
        buildSettings: [.make(variable: "RAW_ENABLE", value: "yes")]
    )

    public init() {}
}
