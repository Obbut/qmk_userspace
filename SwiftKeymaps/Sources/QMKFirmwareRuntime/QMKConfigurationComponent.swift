/// A reusable source of generated QMK configuration settings.
public protocol QMKConfigurationComponent: Sendable {
    /// The settings contributed by this component.
    var qmkBuildSettings: [QMKBuildSetting] { get }
}
