import QMKKeymapKit

/// A key legend paired with its deterministic firmware wire identifier.
public struct AnyLegend: Equatable, Sendable {
    /// The compact identifier emitted to firmware and companion traffic.
    public let id: UInt16

    /// The renderer label.
    public let label: String

    /// The explicitly selected renderer-neutral icon name.
    public let symbolName: String?

    /// Pairs a source legend with its generated wire identifier.
    ///
    /// - Parameters:
    ///   - id: The nonzero generated wire identifier.
    ///   - legend: A legend referenced by the keymap.
    public init(id: UInt16, legend: Legend) {
        precondition(id != 0, "Legend wire identifier zero is reserved for no legend.")
        self.id = id
        label = StaticStringContent.string(legend.label)
        symbolName = legend.icon.map { StaticStringContent.string($0.name) }
    }
}
