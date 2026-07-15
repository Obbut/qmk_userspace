/// A type-checked callback selection paired with an Embedded Swift C symbol.
public struct EmbeddedSwiftHook: Equatable, Sendable {
    /// The QMK callback bridged by the generated ABI glue.
    public let callback: EmbeddedSwiftCallback

    /// The symbol exported from the selected Embedded Swift firmware module.
    public let symbol: String

    /// Creates an Embedded Swift callback hook.
    ///
    /// - Parameters:
    ///   - callback: The QMK callback to extend.
    ///   - symbol: A valid C identifier exported with `@c @implementation`.
    public init(callback: EmbeddedSwiftCallback, symbol: String) {
        precondition(Self.isCIdentifier(symbol), "An Embedded Swift hook must use a C identifier.")
        self.callback = callback
        self.symbol = symbol
    }

    /// Checks that a symbol can safely be emitted at the C ABI boundary.
    ///
    /// - Parameter value: The candidate symbol spelling.
    /// - Returns: Whether the value is a portable C identifier.
    private static func isCIdentifier(_ value: String) -> Bool {
        guard let first = value.utf8.first,
            first == 95 || (65 ... 90).contains(first) || (97 ... 122).contains(first)
        else { return false }
        return value.utf8.dropFirst().allSatisfy {
            $0 == 95 || (48 ... 57).contains($0) || (65 ... 90).contains($0) || (97 ... 122).contains($0)
        }
    }
}
