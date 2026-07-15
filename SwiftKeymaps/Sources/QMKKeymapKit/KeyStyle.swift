/// A reusable strategy that gives a key its portable visual appearance.
public protocol KeyStyle: Sendable {
    /// Produces renderer- and firmware-neutral appearance data.
    ///
    /// - Parameter configuration: The key action and semantic metadata being styled.
    /// - Returns: Appearance data usable by every supported platform.
    func makeAppearance(configuration: KeyStyleConfiguration) -> KeyAppearance
}
