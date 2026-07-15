import QMKKeymapKit

/// A domain-erased visual-style presentation used by firmware and host tooling.
public struct AnyStyle: Equatable, Sendable {
    /// The stable catalog-scoped identifier.
    public let id: UInt16

    /// The style color.
    public let color: RGBColor

    /// Erases a domain-typed style presentation.
    ///
    /// - Parameter style: The presentation to erase.
    public init<ID: KeyStyleID>(_ style: Style<ID>) {
        id = style.id.rawValue
        color = style.color
    }
}
