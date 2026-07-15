/// A host-side declaration that lets Swift type-check a QMK token at the generated C boundary.
public struct QMKToken: Equatable, Hashable, Sendable {
    /// The token spelling emitted at the generated C boundary.
    public let spelling: String

    /// Creates a host-side QMK token declaration.
    ///
    /// - Parameter spelling: The token spelling emitted at the generated C boundary.
    public init(_ spelling: String) {
        precondition(!spelling.isEmpty, "A QMK token cannot be empty.")
        self.spelling = spelling
    }
}
