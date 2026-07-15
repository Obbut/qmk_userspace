import QMKFirmwareRuntime

/// Shared generated QMK configuration for Kyria and Elora.
public struct ObbutHalcyonConfiguration: QMKConfigurationComponent, Sendable {
    public let qmkBuildSettings: [QMKBuildSetting] = [
        .make(variable: "ENCODER_MAP_ENABLE", value: "yes"),
        .make(variable: "OS_DETECTION_ENABLE", value: "yes"),
        .make(variable: "RAW_ENABLE", value: "yes"),
        .make(variable: "USER_NAME", value: "halcyon_modules"),
        .define(name: "SPLIT_TRANSACTION_IDS_USER", value: "USER_SYNC_RGB_PREVIEW"),
        .define(name: "RGB_MATRIX_TIMEOUT", value: "300000"),
    ]

    public init() {}
}
