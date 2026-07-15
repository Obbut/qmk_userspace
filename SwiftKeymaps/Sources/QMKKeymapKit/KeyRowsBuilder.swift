/// Flattens readable rows into the argument order required by a QMK layout macro.
@resultBuilder
public enum KeyRowsBuilder<Domain: KeymapDomain> {
    /// Converts one row into its key sequence.
    ///
    /// - Parameter row: The row to flatten.
    /// - Returns: The row's key sequence.
    public static func buildExpression(_ row: Row<Domain>) -> [Key<Domain>] {
        row.keys
    }

    /// Converts an already composed sequence into a builder component.
    ///
    /// - Parameter keys: The keys to include.
    /// - Returns: The unchanged key sequence.
    public static func buildExpression(_ keys: [Key<Domain>]) -> [Key<Domain>] {
        keys
    }

    /// Flattens all row components.
    ///
    /// - Parameter rows: The row components in declaration order.
    /// - Returns: Keys in QMK layout-macro argument order.
    public static func buildBlock(_ rows: [Key<Domain>]...) -> [Key<Domain>] {
        rows.flatMap { $0 }
    }

    /// Includes an optional row component.
    ///
    /// - Parameter component: The optional component.
    /// - Returns: The component or an empty sequence.
    public static func buildOptional(_ component: [Key<Domain>]?) -> [Key<Domain>] {
        component ?? []
    }

    /// Selects the first conditional branch.
    ///
    /// - Parameter component: The selected component.
    /// - Returns: The selected keys.
    public static func buildEither(first component: [Key<Domain>]) -> [Key<Domain>] {
        component
    }

    /// Selects the second conditional branch.
    ///
    /// - Parameter component: The selected component.
    /// - Returns: The selected keys.
    public static func buildEither(second component: [Key<Domain>]) -> [Key<Domain>] {
        component
    }
}
