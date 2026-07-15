/// A reusable, statically composed keymap fragment.
///
/// Components keep their concrete body type so firmware traversal does not need
/// arrays, existential erasure, reflection, or heap allocation.
public protocol KeymapComponent: Sendable {
    associatedtype Body: KeymapDefinition

    /// The layers and encoders contributed by this component.
    @Keymap
    var body: Body { get }
}
