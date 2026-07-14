// Embedded Swift mappings between QMK adapter values and protocol v3.
// SPDX-License-Identifier: GPL-2.0-or-later

#if hasFeature(Embedded)
    extension KeymapProtocolFirmware {
        /// Calculates the total matrix and encoder entry count.
        ///
        /// - Parameter snapshot: The keymap dimensions to multiply.
        ///
        /// - Returns: The representable entry count, or `nil` for invalid dimensions.
        static func entryCount(
            for snapshot: keymap_protocol_platform_snapshot_t
        ) -> UInt16? {
            guard snapshot.layer_count > 0,
                snapshot.matrix_row_count > 0,
                snapshot.matrix_column_count > 0,
                snapshot.encoder_count > 0
            else {
                return nil
            }
            let layerCount = UInt32(snapshot.layer_count)
            let matrixCount =
                UInt32(snapshot.matrix_row_count)
                * UInt32(snapshot.matrix_column_count)
            let encoderCount =
                UInt32(snapshot.encoder_count)
                * UInt32(KeymapProtocol.encoderDirectionCount)
            let total = layerCount * (matrixCount + encoderCount)
            guard total <= UInt32(UInt16.max) else { return nil }
            return UInt16(total)
        }

        /// Calculates a fingerprint by visiting every adapter-provided keymap entry.
        ///
        /// - Parameters:
        ///   - snapshot: The keymap dimensions included in the fingerprint.
        ///   - keyboardKind: The stable keyboard identifier.
        ///   - entryCount: The validated number of entries.
        /// - Returns: The fingerprint, or `nil` for an unknown adapter role.
        static func fingerprint(
            for snapshot: keymap_protocol_platform_snapshot_t,
            keyboardKind: KeymapProtocol.KeyboardKind,
            entryCount: UInt16
        ) -> UInt32? {
            var hash = KeymapProtocol.fingerprintSeed(
                keyboardKind: keyboardKind.rawValue,
                layerCount: snapshot.layer_count,
                matrixRowCount: snapshot.matrix_row_count,
                matrixColumnCount: snapshot.matrix_column_count,
                encoderCount: snapshot.encoder_count
            )
            for index in 0..<entryCount {
                let entry = keymap_protocol_platform_get_entry(index)
                guard let semantic = semantic(for: entry.semantic_role),
                    let style = style(for: entry.style_role)
                else {
                    return nil
                }
                hash = KeymapProtocol.fingerprint(
                    afterAddingKeycode: entry.keycode,
                    semantic: semantic.rawValue,
                    style: style.rawValue,
                    to: hash
                )
            }
            return hash
        }

        /// Maps an adapter-local keyboard identifier to the stable protocol enum.
        ///
        /// - Parameter value: The adapter identifier.
        ///
        /// - Returns: The shared keyboard kind, or `nil` for an unsupported adapter.
        static func keyboardKind(
            for value: UInt8
        ) -> KeymapProtocol.KeyboardKind? {
            switch value {
            case UInt8(KEYMAP_PROTOCOL_PLATFORM_KEYBOARD_KYRIA):
                .kyria
            case UInt8(KEYMAP_PROTOCOL_PLATFORM_KEYBOARD_ELORA):
                .elora
            default:
                nil
            }
        }

        /// Maps an adapter-local semantic role to the stable protocol enum.
        ///
        /// - Parameter role: The adapter semantic role.
        ///
        /// - Returns: The shared semantic, or `nil` for an invalid role.
        static func semantic(
            for role: UInt8
        ) -> KeymapProtocol.KeySemantic? {
            switch role {
            case UInt8(KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_NONE):
                KeymapProtocol.KeySemantic.none
            case UInt8(KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_SCREENSHOT):
                .screenshot
            case UInt8(KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_AEROSPACE):
                .aerospace
            default:
                nil
            }
        }

        /// Maps an adapter-local presentation role to the stable protocol enum.
        ///
        /// - Parameter role: The adapter presentation role.
        ///
        /// - Returns: The shared style, or `nil` for an invalid role.
        static func style(
            for role: UInt8
        ) -> KeymapProtocol.KeyStyle? {
            switch role {
            case UInt8(KEYMAP_PROTOCOL_PLATFORM_STYLE_STANDARD):
                .standard
            case UInt8(KEYMAP_PROTOCOL_PLATFORM_STYLE_PURPLE):
                .purple
            case UInt8(KEYMAP_PROTOCOL_PLATFORM_STYLE_MAGENTA):
                .magenta
            case UInt8(KEYMAP_PROTOCOL_PLATFORM_STYLE_BLUE):
                .blue
            case UInt8(KEYMAP_PROTOCOL_PLATFORM_STYLE_YELLOW):
                .yellow
            case UInt8(KEYMAP_PROTOCOL_PLATFORM_STYLE_CYAN):
                .cyan
            case UInt8(KEYMAP_PROTOCOL_PLATFORM_STYLE_GREEN):
                .green
            case UInt8(KEYMAP_PROTOCOL_PLATFORM_STYLE_DARK_GREEN):
                .darkGreen
            case UInt8(KEYMAP_PROTOCOL_PLATFORM_STYLE_RED):
                .red
            case UInt8(KEYMAP_PROTOCOL_PLATFORM_STYLE_ORANGE):
                .orange
            default:
                nil
            }
        }

        /// Converts a QMK effect-table index into its stable protocol identifier.
        ///
        /// - Parameter index: The zero-based QMK table position.
        ///
        /// - Returns: A stable RGB effect, or `nil` for an unsupported table entry.
        static func rgbEffect(
            at index: UInt8
        ) -> KeymapProtocol.RGBEffect? {
            guard index < KeymapProtocol.rgbEffectCount else { return nil }
            return KeymapProtocol.RGBEffect(rawValue: index &+ 1)
        }
    }
#endif
