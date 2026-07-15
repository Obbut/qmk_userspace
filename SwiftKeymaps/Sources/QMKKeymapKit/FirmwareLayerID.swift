/// A strongly typed firmware layer identifier backed by QMK's layer index.
public protocol FirmwareLayerID: Sendable {
    /// The zero-based QMK layer index.
    var rawValue: UInt8 { get }
}

public extension FirmwareLayerID {
    /// The type-erased identifier used by keymap metadata and the QMK boundary.
    @_alwaysEmitIntoClient
    @inline(__always)
    var qmkLayerID: LayerID {
        LayerID(rawValue: rawValue)
    }
}
