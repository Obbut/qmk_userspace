/// One QMK matrix coordinate associated with a visible physical switch.
struct MatrixPosition: Equatable, Hashable, Sendable {
    /// The row in QMK's complete split matrix.
    let row: Int

    /// The column in QMK's complete split matrix.
    let column: Int
}
