/// A reusable collection of layers and encoders for one keymap domain.
public protocol KeymapComponent: Sendable {
    /// The keymap domain accepted by the component.
    associatedtype Domain: KeymapDomain

    /// The declarations contributed by this component.
    var keymapElements: [KeymapElement<Domain>] { get }
}
