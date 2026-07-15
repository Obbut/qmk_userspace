/// A reusable collection of layers and encoders.
public protocol KeymapComponent: Sendable {
    /// The declarations contributed by this component.
    var keymapElements: [KeymapElement] { get }
}
