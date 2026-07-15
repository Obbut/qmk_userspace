/// A domain-typed keyboard definition.
public protocol KeymapSpecification<Domain>: Sendable {
    /// The semantic and style domain selected by the keymap.
    associatedtype Domain: KeymapDomain

    /// The stable keymap identifier.
    var id: String { get }

    /// The keyboard layout and physical geometry.
    var layout: LayoutDescriptor { get }

    /// The layers in firmware index order.
    var layers: [Layer<Domain>] { get }

    /// The physical encoders in QMK index order.
    var encoders: [Encoder<Domain>] { get }
}
