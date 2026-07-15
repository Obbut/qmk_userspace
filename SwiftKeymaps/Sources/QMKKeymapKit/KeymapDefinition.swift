/// A statically composed firmware keymap.
public protocol KeymapDefinition: Sendable {
    /// The number of declared layers.
    var layerCount: Int { get }

    /// The number of declared encoders.
    var encoderCount: Int { get }

    /// Returns metadata for a layer ordinal.
    func layer(at ordinal: Int) -> KeymapLayerMetadata?

    /// Returns one layout-order key on a layer ordinal.
    func key(at index: Int, onLayer layerOrdinal: Int) -> Key?

    /// Returns metadata for an encoder ordinal.
    func encoder(at ordinal: Int) -> KeymapEncoderMetadata?

    /// Returns one encoder mapping for a layer and encoder ordinal.
    func encoderMapping(onLayer layerOrdinal: Int, encoderAt encoderOrdinal: Int) -> On?
}
