/// An opaque semantic identifier scoped by a domain catalog fingerprint.
public struct SemanticID: Equatable, Hashable, RawRepresentable, Sendable {
    /// The catalog-scoped wire value, where zero means no semantic override.
    public let rawValue: UInt16

    /// Creates a semantic identifier from its protocol representation.
    ///
    /// - Parameter rawValue: The catalog-scoped wire value.
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    /// The absence of a domain semantic override.
    public static let none = SemanticID(rawValue: 0)
}
