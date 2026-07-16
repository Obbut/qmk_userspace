/// Deterministic byte-level operations for allocation-free static metadata.
public enum StaticStringContent {
    /// Produces a deterministic nonzero protocol content identifier.
    public static func identifier(_ value: StaticString) -> UInt16 {
        let hash = fingerprint(value)
        return foldedIdentifier(hash)
    }

    /// Produces a deterministic identifier from a label and optional secondary value.
    public static func identifier(
        _ value: StaticString,
        secondary: StaticString?
    ) -> UInt16 {
        guard let secondary else { return identifier(value) }
        var hash = fingerprint(value)
        hash = (hash ^ 0xFF) &* 16_777_619
        for index in 0..<secondary.utf8CodeUnitCount {
            hash ^= UInt32(secondary.utf8Start[index])
            hash &*= 16_777_619
        }
        return foldedIdentifier(hash)
    }

    private static func foldedIdentifier(_ hash: UInt32) -> UInt16 {
        let folded = UInt16(truncatingIfNeeded: hash ^ (hash >> 16))
        return folded == 0 ? 1 : folded
    }

    /// Produces the full deterministic FNV-1a fingerprint.
    public static func fingerprint(_ value: StaticString) -> UInt32 {
        var hash: UInt32 = 2_166_136_261
        for index in 0..<value.utf8CodeUnitCount {
            hash ^= UInt32(value.utf8Start[index])
            hash &*= 16_777_619
        }
        return hash
    }

    /// Compares the UTF-8 contents of two static strings.
    public static func equals(_ lhs: StaticString, _ rhs: StaticString) -> Bool {
        guard lhs.utf8CodeUnitCount == rhs.utf8CodeUnitCount else { return false }
        for index in 0..<lhs.utf8CodeUnitCount where lhs.utf8Start[index] != rhs.utf8Start[index] {
            return false
        }
        return true
    }

    /// Feeds a static string's UTF-8 contents into a host hasher.
    public static func hash(_ value: StaticString, into hasher: inout Hasher) {
        for index in 0..<value.utf8CodeUnitCount {
            hasher.combine(value.utf8Start[index])
        }
    }

#if !hasFeature(Embedded)
    /// Materializes static metadata for host-only presentation.
    public static func string(_ value: StaticString) -> String {
        String(describing: value)
    }
#endif
}
