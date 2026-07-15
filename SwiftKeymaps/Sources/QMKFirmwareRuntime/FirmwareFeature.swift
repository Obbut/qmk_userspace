/// A reusable firmware behavior composed by a board module.
public protocol FirmwareFeature: Sendable {
    /// Metadata used by the direct Swift/QMK build.
    var firmwareFeatureDescriptor: FirmwareFeatureDescriptor { get }
}
