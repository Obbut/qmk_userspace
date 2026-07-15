/// A validated keyboard definition.
public protocol KeymapSpecification: Sendable {
    /// The stable keymap identifier.
    var id: String { get }

    /// The keyboard layout and physical geometry.
    var layout: LayoutDescriptor { get }

    /// The layers in firmware index order.
    var layers: [Layer] { get }

    /// The physical encoders in QMK index order.
    var encoders: [Encoder] { get }
}
