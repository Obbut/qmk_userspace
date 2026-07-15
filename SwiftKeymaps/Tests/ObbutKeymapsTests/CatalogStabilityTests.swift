import ObbutKeymaps
import QMKKeymapKit
import Testing

/// Verifies catalog fingerprints remain stable protocol contracts.
@Test
func catalogFingerprintsAreStable() {
    #expect(CatalogFingerprint.semantics(ObbutKeymapDomain.semantics) == 795_804_440)
    #expect(CatalogFingerprint.styles(ObbutKeymapDomain.styles) == 1_352_912_009)
}

/// Verifies all declared semantic and style identifiers are unique and explicit.
@Test
func catalogIdentifiersAreUnique() {
    let semanticIDs = ObbutKeymapDomain.semantics.entries.map(\.id.rawValue)
    let styleIDs = ObbutKeymapDomain.styles.entries.map(\.id.rawValue)

    #expect(Set(semanticIDs).count == semanticIDs.count)
    #expect(Set(styleIDs).count == styleIDs.count)
    #expect(semanticIDs.min() == 1)
    #expect(styleIDs.min() == 0)
}
