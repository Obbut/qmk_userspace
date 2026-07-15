import QMKKeymapKit

/// Semantic metadata paired with its generated firmware wire identifier.
public struct AnySemantic: Equatable, Sendable {
    /// The compact identifier emitted to firmware and companion traffic.
    public let id: UInt16

    /// The source-level stable identifier.
    public let stableID: String

    /// The fallback renderer legend.
    public let legend: String

    /// The optional renderer-neutral symbol name.
    public let symbolName: String?

    /// Pairs collected semantic metadata with its generated wire identifier.
    ///
    /// - Parameters:
    ///   - id: The nonzero generated wire identifier.
    ///   - semantic: Semantic metadata referenced by the keymap.
    public init(id: UInt16, semantic: KeySemantic) {
        precondition(id != 0, "Semantic wire identifier zero is reserved for no semantic.")
        self.id = id
        stableID = StaticStringContent.string(semantic.id)
        legend = StaticStringContent.string(semantic.legend)
        symbolName = semantic.symbol.map { StaticStringContent.string($0.name) }
    }
}
