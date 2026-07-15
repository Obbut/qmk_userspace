/// A stable, type-erased QMK layer index.
public struct LayerID: Equatable, FirmwareLayerID, Hashable, Sendable {
    /// The QMK layer index.
    public let rawValue: UInt8

    /// Creates a layer identifier.
    ///
    /// - Parameter rawValue: The QMK layer index.
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}
