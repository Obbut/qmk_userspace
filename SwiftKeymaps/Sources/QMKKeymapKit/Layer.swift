/// A keymap layer in layout-macro argument order.
public struct Layer: Sendable {
    /// The stable layer identifier.
    public let id: LayerID

    /// The name shown by companions and previews.
    public let name: String

    /// Whether activating this layer should show the transient HUD.
    public let showsHUD: Bool

    /// The QMK layout-macro arguments.
    public let keys: [Key]

    /// Creates a layer from readable rows.
    ///
    /// - Parameters:
    ///   - id: The stable layer identifier.
    ///   - name: The name shown by companions and previews.
    ///   - showsHUD: Whether activating this layer should show the transient HUD.
    ///   - content: The key rows in QMK layout-macro argument order.
    public init(
        _ id: LayerID,
        name: String,
        showsHUD: Bool = false,
        @KeyRowsBuilder content: () -> [Key]
    ) {
        self.id = id
        self.name = name
        self.showsHUD = showsHUD
        keys = content()
    }
}
