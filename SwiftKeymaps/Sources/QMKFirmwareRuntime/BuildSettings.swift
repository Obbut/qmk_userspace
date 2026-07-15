/// A small reusable component containing explicit QMK build settings.
public struct BuildSettings: QMKConfigurationComponent, Sendable {
    /// The settings contributed by this component.
    public let qmkBuildSettings: [QMKBuildSetting]

    /// Creates a component from explicit settings.
    ///
    /// - Parameter settings: The settings to contribute.
    public init(_ settings: QMKBuildSetting...) {
        qmkBuildSettings = settings
    }
}
