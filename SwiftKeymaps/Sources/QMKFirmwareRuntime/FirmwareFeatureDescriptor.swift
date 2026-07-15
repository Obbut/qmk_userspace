/// Build and callback metadata for one reusable firmware feature.
public struct FirmwareFeatureDescriptor: Equatable, Sendable {
    /// The stable feature identifier.
    public let id: String

    /// QMK build settings required by the feature.
    public let buildSettings: [QMKBuildSetting]

    /// Generated C declarations placed before callback entry points.
    public let cDeclarations: [String]

    /// Typed callbacks implemented by the selected Embedded Swift module.
    public let embeddedSwiftHooks: [EmbeddedSwiftHook]

    /// Creates a firmware-feature descriptor.
    ///
    /// - Parameters:
    ///   - id: The stable feature identifier.
    ///   - buildSettings: QMK build settings required by the feature.
    ///   - cDeclarations: Generated C declarations placed before callback entry points.
    ///   - embeddedSwiftHooks: Typed callbacks implemented by Embedded Swift.
    public init(
        id: String,
        buildSettings: [QMKBuildSetting] = [],
        cDeclarations: [String] = [],
        embeddedSwiftHooks: [EmbeddedSwiftHook] = []
    ) {
        precondition(!id.isEmpty, "A firmware feature identifier cannot be empty.")
        self.id = id
        self.buildSettings = buildSettings
        self.cDeclarations = cDeclarations
        self.embeddedSwiftHooks = embeddedSwiftHooks
    }
}
