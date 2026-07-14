/// One QMK matrix coordinate associated with a visible physical switch.
public struct MatrixPosition: Equatable, Hashable, Sendable {
    /// The zero-based matrix row.
    public let row: Int

    /// The zero-based matrix column.
    public let column: Int

    /// Creates a QMK matrix position.
    ///
    /// - Parameters:
    ///   - row: The zero-based matrix row.
    ///   - column: The zero-based matrix column.
    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
}
