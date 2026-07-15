import QMKKeymapKit

/// Deterministic wire metadata collected from the keys referenced by one firmware.
struct GeneratedKeyMetadata: Sendable {
    /// Semantics in generated wire-ID order.
    let semantics: [AnySemantic]

    /// Appearances in generated wire-ID order, including standard style zero.
    let styles: [AnyStyle]

    /// The fingerprint covering every referenced semantic.
    let semanticFingerprint: UInt32

    /// The fingerprint covering every resolved appearance.
    let styleFingerprint: UInt32

    fileprivate let semanticIDs: [String: UInt16]
    fileprivate let styleIDs: [KeyAppearance: UInt16]

    /// Collects and validates metadata from every matrix and encoder action.
    ///
    /// - Parameter keys: Every action reachable from the firmware keymap.
    init(keys: [Key]) {
        var semanticValuesByID: [String: KeySemantic] = [:]
        for semantic in keys.compactMap(\.semantic) {
            let stableID = StaticStringContent.string(semantic.id)
            if let existing = semanticValuesByID[stableID] {
                precondition(
                    existing == semantic,
                    "Semantic \(semantic.id) has conflicting presentation metadata."
                )
            } else {
                semanticValuesByID[stableID] = semantic
            }
        }

        let semanticValues = semanticValuesByID.values.sorted {
            StaticStringContent.string($0.id) < StaticStringContent.string($1.id)
        }
        precondition(
            semanticValues.count <= Int(UInt16.max),
            "Firmware metadata supports at most \(UInt16.max) semantics."
        )
        let semanticPairs = semanticValues.map { semantic in
            (StaticStringContent.string(semantic.id), semantic.contentID, semantic)
        }
        precondition(
            Set(semanticPairs.map(\.1)).count == semanticPairs.count,
            "Semantic protocol content identifiers must not collide."
        )
        semanticIDs = Dictionary(
            uniqueKeysWithValues: semanticPairs.map { ($0.0, $0.1) }
        )
        semantics = semanticPairs.map { AnySemantic(id: $0.1, semantic: $0.2) }
        semanticFingerprint = KeymapMetadataFingerprint.semantics(semanticValues)

        let customAppearances = Set(keys.map(\.appearance))
            .subtracting([.standard])
            .sorted { $0.contentID < $1.contentID }
        precondition(
            customAppearances.count <= Int(UInt16.max),
            "Firmware metadata supports at most \(UInt16.max) custom appearances."
        )
        let appearances = [KeyAppearance.standard] + customAppearances
        precondition(
            Set(appearances.map(\.contentID)).count == appearances.count,
            "Style protocol content identifiers must not collide."
        )
        styleIDs = Dictionary(
            uniqueKeysWithValues: appearances.map { appearance in
                (appearance, appearance.contentID)
            }
        )
        styles = appearances.map { appearance in
            AnyStyle(id: appearance.contentID, appearance: appearance)
        }
        styleFingerprint = KeymapMetadataFingerprint.styles(appearances)
    }

    /// Returns the generated semantic wire identifier for a key.
    func semanticID(for key: Key) -> UInt16? {
        guard let semantic = key.semantic else { return nil }
        guard let id = semanticIDs[StaticStringContent.string(semantic.id)] else {
            preconditionFailure("Every key semantic must be collected before erasure.")
        }
        return id
    }

    /// Returns the generated style wire identifier for a key.
    func styleID(for key: Key) -> UInt16 {
        guard let id = styleIDs[key.appearance] else {
            preconditionFailure("Every key appearance must be collected before erasure.")
        }
        return id
    }
}
