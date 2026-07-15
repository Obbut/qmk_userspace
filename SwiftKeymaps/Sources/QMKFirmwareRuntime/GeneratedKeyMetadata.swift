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
            if let existing = semanticValuesByID[semantic.id] {
                precondition(
                    existing == semantic,
                    "Semantic \(semantic.id) has conflicting presentation metadata."
                )
            } else {
                semanticValuesByID[semantic.id] = semantic
            }
        }

        let semanticValues = semanticValuesByID.values.sorted { $0.id < $1.id }
        precondition(
            semanticValues.count <= Int(UInt16.max),
            "Firmware metadata supports at most \(UInt16.max) semantics."
        )
        let semanticPairs = semanticValues.enumerated().map { offset, semantic in
            (semantic.id, UInt16(offset + 1), semantic)
        }
        semanticIDs = Dictionary(
            uniqueKeysWithValues: semanticPairs.map { ($0.0, $0.1) }
        )
        semantics = semanticPairs.map { AnySemantic(id: $0.1, semantic: $0.2) }
        semanticFingerprint = KeymapMetadataFingerprint.semantics(semanticValues)

        let customAppearances = Set(keys.map(\.appearance))
            .subtracting([.standard])
            .sorted { lhs, rhs in
                (lhs.color.red, lhs.color.green, lhs.color.blue)
                    < (rhs.color.red, rhs.color.green, rhs.color.blue)
            }
        precondition(
            customAppearances.count <= Int(UInt16.max),
            "Firmware metadata supports at most \(UInt16.max) custom appearances."
        )
        let appearances = [KeyAppearance.standard] + customAppearances
        styleIDs = Dictionary(
            uniqueKeysWithValues: appearances.enumerated().map { offset, appearance in
                (appearance, UInt16(offset))
            }
        )
        styles = appearances.enumerated().map { offset, appearance in
            AnyStyle(id: UInt16(offset), appearance: appearance)
        }
        styleFingerprint = KeymapMetadataFingerprint.styles(appearances)
    }

    /// Returns the generated semantic wire identifier for a key.
    func semanticID(for key: Key) -> UInt16? {
        guard let semantic = key.semantic else { return nil }
        guard let id = semanticIDs[semantic.id] else {
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
