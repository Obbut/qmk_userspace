/// A generated legend identifier scoped by its metadata fingerprint.
public struct LegendID: Equatable, Hashable, RawRepresentable, Sendable {
    /// The generated wire value, where zero means no explicit legend.
    public let rawValue: UInt16

    /// Creates a legend identifier from its protocol representation.
    ///
    /// - Parameter rawValue: The generated wire value.
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    /// The absence of an explicit legend.
    public static let none = LegendID(rawValue: 0)
}
