import QMKKeymapKit

/// Stable FNV-1a fingerprints for generated key metadata and layout identifiers.
public enum KeymapMetadataFingerprint {
    /// Calculates a fingerprint for automatically collected legends.
    ///
    /// - Parameter legends: Legends in generated wire-ID order.
    /// - Returns: A stable fingerprint covering every label.
    public static func legends(_ legends: [Legend]) -> UInt32 {
        legends.enumerated().reduce(seed) { hash, element in
            var next = afterAdding(UInt16(element.offset + 1), to: hash)
            next = afterAdding(element.element.label, to: next)
            if let icon = element.element.icon {
                next = afterAdding(icon.name, to: next)
            }
            return next
        }
    }

    /// Calculates a fingerprint for automatically collected appearances.
    ///
    /// - Parameter appearances: Appearances in generated wire-ID order.
    /// - Returns: A stable fingerprint covering every portable color.
    public static func styles(_ appearances: [KeyAppearance]) -> UInt32 {
        appearances.enumerated().reduce(seed) { hash, element in
            var next = afterAdding(UInt16(element.offset), to: hash)
            next = afterAdding(element.element.color.red, to: next)
            next = afterAdding(element.element.color.green, to: next)
            return afterAdding(element.element.color.blue, to: next)
        }
    }

    /// Calculates a stable fingerprint for an arbitrary UTF-8 identifier.
    ///
    /// - Parameter identifier: The identifier to fingerprint.
    /// - Returns: The stable FNV-1a fingerprint.
    public static func identifier(_ identifier: String) -> UInt32 {
        identifier.utf8.reduce(seed) { afterAdding($1, to: $0) }
    }

    fileprivate static let seed: UInt32 = 2_166_136_261

    fileprivate static func afterAdding(_ value: UInt16, to hash: UInt32) -> UInt32 {
        afterAdding(
            UInt8(truncatingIfNeeded: value >> 8),
            to: afterAdding(UInt8(truncatingIfNeeded: value), to: hash)
        )
    }

    fileprivate static func afterAdding(_ value: String, to hash: UInt32) -> UInt32 {
        value.utf8.reduce(hash) { afterAdding($1, to: $0) }
            .addingFieldDelimiter
    }

    fileprivate static func afterAdding(_ value: StaticString, to hash: UInt32) -> UInt32 {
        var result = hash
        for index in 0..<value.utf8CodeUnitCount {
            result = afterAdding(value.utf8Start[index], to: result)
        }
        return result.addingFieldDelimiter
    }

    fileprivate static func afterAdding(_ byte: UInt8, to hash: UInt32) -> UInt32 {
        (hash ^ UInt32(byte)) &* 16_777_619
    }
}

fileprivate extension UInt32 {
    var addingFieldDelimiter: UInt32 {
        (self ^ 0xFF) &* 16_777_619
    }
}
