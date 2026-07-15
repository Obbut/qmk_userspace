/// Build settings and header directives emitted for QMK.
public struct QMKConfiguration: QMKConfigurationComponent, Sendable {
    /// The settings written to generated build artifacts.
    public let qmkBuildSettings: [QMKBuildSetting]

    /// Creates a configuration from reusable components.
    ///
    /// - Parameter content: The configuration components.
    public init(
        @QMKConfigurationBuilder content: () -> [QMKBuildSetting]
    ) {
        qmkBuildSettings = content()
    }
}
