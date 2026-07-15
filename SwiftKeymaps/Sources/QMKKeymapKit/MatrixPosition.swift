/// One QMK matrix coordinate associated with a physical control.
public struct MatrixPosition: Equatable, Hashable, Sendable {
    /// The zero-based matrix row.
    public let row: Int

    /// The zero-based matrix column.
    public let column: Int

    /// Creates a matrix coordinate.
    ///
    /// - Parameters:
    ///   - row: The zero-based matrix row.
    ///   - column: The zero-based matrix column.
    public init(row: Int, column: Int) {
        precondition(row >= 0 && column >= 0, "Matrix coordinates cannot be negative.")
        self.row = row
        self.column = column
    }
}
