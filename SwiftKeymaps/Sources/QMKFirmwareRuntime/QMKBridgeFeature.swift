/// A last-resort, typed bridge from generated QMK callbacks into custom Swift.
public struct QMKBridgeFeature: FirmwareFeature, Sendable {
    /// Build metadata consumed by the host keymap compiler.
    public let firmwareFeatureDescriptor: FirmwareFeatureDescriptor

    /// Creates a custom Embedded Swift bridge feature.
    ///
    /// - Parameters:
    ///   - id: A stable feature identifier.
    ///   - hooks: Typed callback-to-symbol mappings.
    public init(id: String, hooks: [EmbeddedSwiftHook]) {
        firmwareFeatureDescriptor = FirmwareFeatureDescriptor(
            id: id,
            embeddedSwiftHooks: hooks
        )
    }
}
