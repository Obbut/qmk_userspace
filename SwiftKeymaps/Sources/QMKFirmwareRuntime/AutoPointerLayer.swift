import QMKKeymapKit

/// Generated QMK automatic-pointer-layer configuration.
public struct AutoPointerLayer: QMKConfigurationComponent, Sendable {
    /// The settings contributed by this component.
    public let qmkBuildSettings: [QMKBuildSetting]

    /// Creates automatic-pointer-layer settings.
    ///
    /// - Parameters:
    ///   - layer: The pointer layer activated by motion.
    ///   - timeout: The inactivity timeout before leaving the layer.
    ///   - delay: The delay before pointer activation is eligible.
    ///   - debounce: The pointer activation debounce.
    ///   - threshold: The motion threshold that activates the layer.
    public init(
        _ layer: LayerID,
        timeout: QMKDuration,
        delay: QMKDuration = .milliseconds(200),
        debounce: QMKDuration = .milliseconds(25),
        threshold: Int = 10
    ) {
        precondition(threshold > 0, "The automatic pointer threshold must be positive.")
        qmkBuildSettings = [
            .define(name: "POINTING_DEVICE_AUTO_MOUSE_ENABLE", value: nil),
            .define(name: "AUTO_MOUSE_DEFAULT_LAYER", value: String(layer.rawValue)),
            .define(name: "AUTO_MOUSE_TIME", value: String(timeout.milliseconds)),
            .define(name: "AUTO_MOUSE_DELAY", value: String(delay.milliseconds)),
            .define(name: "AUTO_MOUSE_DEBOUNCE", value: String(debounce.milliseconds)),
            .define(name: "AUTO_MOUSE_THRESHOLD", value: String(threshold)),
        ]
    }
}
