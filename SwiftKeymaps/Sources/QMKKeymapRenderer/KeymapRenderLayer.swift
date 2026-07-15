/// One authored firmware layer available to renderers.
public struct KeymapRenderLayer: Equatable, Identifiable, Sendable {
    /// The QMK layer index.
    public let id: UInt8

    /// The authored user-facing name.
    public let name: String

    /// Whether activation is eligible for the layer HUD.
    public let showsHUD: Bool

    /// Creates a renderer layer.
    public init(id: UInt8, name: String, showsHUD: Bool) {
        self.id = id
        self.name = name
        self.showsHUD = showsHUD
    }
}
