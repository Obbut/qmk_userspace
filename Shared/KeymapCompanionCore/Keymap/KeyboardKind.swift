/// The keyboard identifier shared by firmware and companion apps.
public typealias KeyboardKind = KeymapProtocol.KeyboardKind

extension KeymapProtocol.KeyboardKind {
    /// The product name shown by companion apps.
    public var displayName: String {
        switch self {
        case .kyria:
            "Kyria Rev4"
        case .elora:
            "Elora Rev2"
        }
    }
}
