extension KeymapProtocol {
    /// A keyboard model represented on the wire.
    public enum KeyboardKind: UInt8, CaseIterable, Equatable, Sendable {
        /// The splitkb Kyria Rev4.
        case kyria = 1

        /// The splitkb Elora Rev2.
        case elora = 2
    }
}
