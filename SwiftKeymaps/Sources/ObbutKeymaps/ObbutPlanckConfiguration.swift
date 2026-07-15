import QMKFirmwareRuntime

/// Generated QMK configuration for the ZSA Planck EZ Glow.
public struct ObbutPlanckConfiguration: QMKConfigurationComponent, Sendable {
    /// The Planck build and header settings.
    public let qmkBuildSettings: [QMKBuildSetting] = [
        .make(variable: "OS_DETECTION_ENABLE", value: "yes"),
        .make(variable: "TRI_LAYER_ENABLE", value: "yes"),
        .make(variable: "OPT_DEFS +", value: "-DCOMMUNITY_MODULE_DEFAULTS_ENABLE"),
        .make(variable: "VPATH +", value: "modules/zsa/defaults"),
        .make(variable: "POST_CONFIG_H +", value: "keyboards/zsa/common/keycode_aliases.h"),
        .define(name: "PERMISSIVE_HOLD", value: nil),
        .undefine(name: "RGB_MATRIX_TIMEOUT"),
        .define(name: "RGB_MATRIX_TIMEOUT", value: "300000"),
        .define(name: "PLANCK_EZ_LED_LOWER", value: "2"),
        .define(name: "PLANCK_EZ_LED_RAISE", value: "3"),
        .define(name: "PLANCK_EZ_LED_ADJUST", value: "4"),
        .define(name: "TRI_LAYER_LOWER_LAYER", value: "2"),
        .define(name: "TRI_LAYER_UPPER_LAYER", value: "3"),
        .define(name: "TRI_LAYER_ADJUST_LAYER", value: "4"),
    ]

    /// Creates the Planck configuration.
    public init() {}
}
