import QMKFirmwareRuntime

/// Generated QMK configuration for the Keychron Q15 Max.
public struct ObbutQ15Configuration: QMKConfigurationComponent, Sendable {
    public let qmkBuildSettings: [QMKBuildSetting] = [
        .make(variable: "ENCODER_MAP_ENABLE", value: "yes"),
        .make(variable: "LDFLAGS +", value: "-Wl,--wrap=raw_hid_receive"),
        .define(name: "PERMISSIVE_HOLD", value: nil),
        .undefine(name: "RGB_MATRIX_TIMEOUT"),
        .define(name: "RGB_MATRIX_TIMEOUT", value: "300000"),
    ]

    public init() {}
}
