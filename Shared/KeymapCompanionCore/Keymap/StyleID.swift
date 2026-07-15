/// An opaque visual-style identifier scoped by a domain catalog fingerprint.
public struct StyleID: Equatable, Hashable, RawRepresentable, Sendable {
    /// The catalog-scoped wire value.
    public let rawValue: UInt16

    /// Creates a style identifier from its protocol representation.
    ///
    /// - Parameter rawValue: The catalog-scoped wire value.
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    /// The conventional unaccented style identifier.
    public static let standard = StyleID(rawValue: 0)
}
