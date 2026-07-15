/// A generated semantic identifier scoped by its metadata fingerprint.
public struct SemanticID: Equatable, Hashable, RawRepresentable, Sendable {
    /// The generated wire value, where zero means no semantic metadata.
    public let rawValue: UInt16

    /// Creates a semantic identifier from its protocol representation.
    ///
    /// - Parameter rawValue: The generated wire value.
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    /// The absence of semantic metadata.
    public static let none = SemanticID(rawValue: 0)
}
