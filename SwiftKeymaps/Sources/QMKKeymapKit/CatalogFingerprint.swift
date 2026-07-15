/// Stable FNV-1a fingerprints for domain catalogs and keymap documents.
public enum CatalogFingerprint {
    /// Calculates a semantic-catalog fingerprint.
    ///
    /// - Parameter catalog: The semantic catalog to fingerprint.
    /// - Returns: The stable FNV-1a fingerprint.
    public static func semantics<Catalog: SemanticCatalog>(
        _ catalog: Catalog
    ) -> UInt32 {
        catalog.entries.reduce(seed) { hash, entry in
            fingerprint(entry.legend.utf8, afterAdding: entry.id.rawValue, to: hash)
        }
    }

    /// Calculates a style-catalog fingerprint.
    ///
    /// - Parameter catalog: The style catalog to fingerprint.
    /// - Returns: The stable FNV-1a fingerprint.
    public static func styles<Catalog: StyleCatalog>(
        _ catalog: Catalog
    ) -> UInt32 {
        catalog.entries.reduce(seed) { hash, entry in
            var next = afterAdding(entry.id.rawValue, to: hash)
            next = afterAdding(entry.color.red, to: next)
            next = afterAdding(entry.color.green, to: next)
            return afterAdding(entry.color.blue, to: next)
        }
    }

    /// Calculates a stable fingerprint for an arbitrary UTF-8 identifier.
    ///
    /// - Parameter identifier: The identifier to fingerprint.
    /// - Returns: The stable FNV-1a fingerprint.
    public static func identifier(_ identifier: String) -> UInt32 {
        identifier.utf8.reduce(seed) { afterAdding($1, to: $0) }
    }

    /// The FNV-1a 32-bit seed.
    fileprivate static let seed: UInt32 = 2_166_136_261

    /// Adds a 16-bit value to a fingerprint.
    fileprivate static func afterAdding(_ value: UInt16, to hash: UInt32) -> UInt32 {
        afterAdding(UInt8(truncatingIfNeeded: value >> 8), to: afterAdding(UInt8(truncatingIfNeeded: value), to: hash))
    }

    /// Adds one byte to a fingerprint.
    fileprivate static func afterAdding(_ byte: UInt8, to hash: UInt32) -> UInt32 {
        (hash ^ UInt32(byte)) &* 16_777_619
    }

    /// Adds an identifier after a 16-bit catalog value.
    fileprivate static func fingerprint<Bytes: Sequence>(
        _ bytes: Bytes,
        afterAdding value: UInt16,
        to hash: UInt32
    ) -> UInt32 where Bytes.Element == UInt8 {
        bytes.reduce(afterAdding(value, to: hash)) { afterAdding($1, to: $0) }
    }
}
