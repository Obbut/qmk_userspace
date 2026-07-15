/// Composes reusable QMK configuration components.
@resultBuilder
public enum QMKConfigurationBuilder {
    /// Converts one component into generated settings.
    ///
    /// - Parameter component: The component to include.
    /// - Returns: The component's generated settings.
    public static func buildExpression<Component: QMKConfigurationComponent>(
        _ component: Component
    ) -> [QMKBuildSetting] {
        component.qmkBuildSettings
    }

    /// Converts one setting into a builder component.
    ///
    /// - Parameter setting: The setting to include.
    /// - Returns: A single-setting component.
    public static func buildExpression(_ setting: QMKBuildSetting) -> [QMKBuildSetting] {
        [setting]
    }

    /// Flattens configuration components.
    ///
    /// - Parameter components: The components in declaration order.
    /// - Returns: The complete generated configuration.
    public static func buildBlock(_ components: [QMKBuildSetting]...) -> [QMKBuildSetting] {
        components.flatMap { $0 }
    }

    /// Includes an optional configuration component.
    ///
    /// - Parameter component: The optional component.
    /// - Returns: The component or an empty sequence.
    public static func buildOptional(_ component: [QMKBuildSetting]?) -> [QMKBuildSetting] {
        component ?? []
    }

    /// Selects the first conditional branch.
    ///
    /// - Parameter component: The selected component.
    /// - Returns: The selected settings.
    public static func buildEither(first component: [QMKBuildSetting]) -> [QMKBuildSetting] {
        component
    }

    /// Selects the second conditional branch.
    ///
    /// - Parameter component: The selected component.
    /// - Returns: The selected settings.
    public static func buildEither(second component: [QMKBuildSetting]) -> [QMKBuildSetting] {
        component
    }
}
