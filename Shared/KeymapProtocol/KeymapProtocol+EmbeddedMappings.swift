// Embedded keymap calculations for protocol v5.
// SPDX-License-Identifier: GPL-2.0-or-later

#if hasFeature(Embedded)
    /// Protocol-v5 calculations over the narrow generated-keymap C boundary.
    extension KeymapProtocolFirmware {
        /// Calculates the total matrix and encoder entry count.
        static func entryCount(
            for snapshot: keymap_protocol_platform_snapshot_t
        ) -> UInt16? {
            guard snapshot.layer_count > 0,
                snapshot.matrix_row_count > 0,
                snapshot.matrix_column_count > 0
            else { return nil }
            let layerCount = UInt32(snapshot.layer_count)
            let matrixCount = UInt32(snapshot.matrix_row_count) * UInt32(snapshot.matrix_column_count)
            let encoderCount = UInt32(snapshot.encoder_count) * UInt32(KeymapProtocol.encoderDirectionCount)
            let total = layerCount * (matrixCount + encoderCount)
            guard total <= UInt32(UInt16.max) else { return nil }
            return UInt16(total)
        }

        /// Calculates the keymap fingerprint by visiting generated entries.
        static func fingerprint(
            for snapshot: keymap_protocol_platform_snapshot_t,
            entryCount: UInt16
        ) -> UInt32 {
            var hash = KeymapProtocol.fingerprintSeed(
                layoutID: snapshot.layout_id,
                layerCount: snapshot.layer_count,
                matrixRowCount: snapshot.matrix_row_count,
                matrixColumnCount: snapshot.matrix_column_count,
                encoderCount: snapshot.encoder_count
            )
            for index in 0..<entryCount {
                let entry = keymap_protocol_platform_get_entry(index)
                hash = KeymapProtocol.fingerprint(
                    afterAddingKeycode: entry.keycode,
                    legendID: entry.legend_id,
                    styleID: entry.style_id,
                    to: hash
                )
            }
            return hash
        }
    }
#endif
