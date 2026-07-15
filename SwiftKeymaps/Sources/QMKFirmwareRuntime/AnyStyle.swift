import QMKKeymapKit

/// Portable appearance paired with its generated firmware wire identifier.
public struct AnyStyle: Equatable, Sendable {
    /// The compact identifier emitted to firmware and companion traffic.
    public let id: UInt16

    /// The color resolved from the source-level key style.
    public let color: RGBColor

    /// Pairs a resolved appearance with its generated wire identifier.
    ///
    /// - Parameters:
    ///   - id: The generated wire identifier, where zero means the standard appearance.
    ///   - appearance: Portable appearance produced by a key style.
    public init(id: UInt16, appearance: KeyAppearance) {
        self.id = id
        color = appearance.color
    }
}
