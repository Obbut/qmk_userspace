/// A stable layer index and generated C identifier.
public struct LayerID: Equatable, Hashable, Sendable {
    /// The QMK layer index.
    public let rawValue: UInt8

    /// The identifier emitted into generated C.
    public let cIdentifier: String

    /// Creates a layer identifier.
    ///
    /// - Parameters:
    ///   - rawValue: The QMK layer index.
    ///   - cIdentifier: The identifier emitted into generated C.
    public init(rawValue: UInt8, cIdentifier: String) {
        precondition(!cIdentifier.isEmpty, "A layer C identifier cannot be empty.")
        self.rawValue = rawValue
        self.cIdentifier = cIdentifier
    }
}
