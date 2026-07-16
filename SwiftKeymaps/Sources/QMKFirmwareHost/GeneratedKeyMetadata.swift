import QMKKeymapKit

/// Deterministic wire metadata collected from the keys referenced by one firmware.
struct GeneratedKeyMetadata: Sendable {
    /// Legends in generated wire-ID order.
    let legends: [AnyLegend]

    /// Appearances in generated wire-ID order, including standard style zero.
    let styles: [AnyStyle]

    /// The fingerprint covering every referenced legend.
    let legendFingerprint: UInt32

    /// The fingerprint covering every resolved appearance.
    let styleFingerprint: UInt32

    fileprivate let legendIDs: [String: UInt16]
    fileprivate let styleIDs: [KeyAppearance: UInt16]

    /// Collects and validates metadata from every matrix and encoder action.
    ///
    /// - Parameter keys: Every action reachable from the firmware keymap.
    init(keys: [Key]) {
        var legendValuesByLabel: [String: StaticString] = [:]
        for legend in keys.compactMap(\.legend) {
            legendValuesByLabel[StaticStringContent.string(legend)] = legend
        }

        let legendValues = legendValuesByLabel.values.sorted {
            StaticStringContent.string($0) < StaticStringContent.string($1)
        }
        precondition(
            legendValues.count <= Int(UInt16.max),
            "Firmware metadata supports at most \(UInt16.max) legends."
        )
        let legendPairs = legendValues.map { legend in
            (StaticStringContent.string(legend), StaticStringContent.identifier(legend), legend)
        }
        precondition(
            Set(legendPairs.map(\.1)).count == legendPairs.count,
            "Legend protocol content identifiers must not collide."
        )
        legendIDs = Dictionary(
            uniqueKeysWithValues: legendPairs.map { ($0.0, $0.1) }
        )
        legends = legendPairs.map { AnyLegend(id: $0.1, legend: $0.2) }
        legendFingerprint = KeymapMetadataFingerprint.legends(legendValues)

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

    /// Returns the generated legend wire identifier for a key.
    func legendID(for key: Key) -> UInt16? {
        guard let legend = key.legend else { return nil }
        guard let id = legendIDs[StaticStringContent.string(legend)] else {
            preconditionFailure("Every key legend must be collected before erasure.")
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
