/// A semantic and visual vocabulary selected by a family of keymaps.
public protocol KeymapDomain: Sendable {
    /// The domain-owned semantic identifier type.
    associatedtype Semantic: KeySemanticID

    /// The domain-owned style identifier type.
    associatedtype Style: KeyStyleID

    associatedtype Semantics: SemanticCatalog where Semantics.ID == Semantic

    associatedtype Styles: StyleCatalog where Styles.ID == Style

    /// Presentation for every semantic emitted by this domain.
    @SemanticCatalogBuilder static var semantics: Semantics { get }

    /// Presentation for every style emitted by this domain.
    @StyleCatalogBuilder static var styles: Styles { get }
}
