/// A generated style identifier scoped by its metadata fingerprint.
public struct StyleID: Equatable, Hashable, RawRepresentable, Sendable {
    /// The generated wire value.
    public let rawValue: UInt16

    /// Creates a style identifier from its protocol representation.
    ///
    /// - Parameter rawValue: The generated wire value.
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    /// The standard appearance identifier generated for every firmware.
    public static let standard = StyleID(rawValue: 0)
}
