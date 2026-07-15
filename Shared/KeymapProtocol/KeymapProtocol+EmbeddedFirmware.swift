// Firmware-side protocol-v4 engine.
// SPDX-License-Identifier: GPL-2.0-or-later

#if hasFeature(Embedded)
    /// The allocation-free protocol-v4 runtime serialized on QMK's event loop.
    enum KeymapProtocolFirmware {
        /// The minimum delay between unsolicited reports.
        fileprivate static let minimumSendInterval: UInt32 = 5

        /// Whether a request established a host connection.
        nonisolated(unsafe) fileprivate static var isConnected = false

        /// The sequence written into the next state report.
        nonisolated(unsafe) fileprivate static var sequence: UInt32 = 0

        /// The timestamp of the most recently sent state.
        nonisolated(unsafe) fileprivate static var lastSendTimestamp: UInt32 = 0

        /// The last reported momentary layer mask.
        nonisolated(unsafe) fileprivate static var lastLayerState = UInt32.max

        /// The last reported persistent layer mask.
        nonisolated(unsafe) fileprivate static var lastDefaultLayerState = UInt32.max

        /// The last reported RGB capability flag.
        nonisolated(unsafe) fileprivate static var lastIncludesRGBSettings = UInt8.max

        /// The last reported RGB effect.
        nonisolated(unsafe) fileprivate static var lastRGBEffectIndex = UInt8.max

        /// The last reported RGB hue.
        nonisolated(unsafe) fileprivate static var lastRGBHue = UInt8.max

        /// The last reported RGB saturation.
        nonisolated(unsafe) fileprivate static var lastRGBSaturation = UInt8.max

        /// The last reported RGB brightness.
        nonisolated(unsafe) fileprivate static var lastRGBBrightness = UInt8.max

        /// The last reported RGB enabled flag.
        nonisolated(unsafe) fileprivate static var lastRGBEnabled = UInt8.max

        /// The last reported RGB speed.
        nonisolated(unsafe) fileprivate static var lastRGBSpeed = UInt8.max

        /// Handles one complete Raw HID report supplied by QMK.
        static func receive(_ data: UnsafePointer<UInt8>, length: UInt8) {
            let bytes = UnsafeBufferPointer(start: data, count: Int(length))
            guard let messageType = KeymapProtocol.messageType(in: bytes) else { return }
            switch messageType {
            case .getState:
                isConnected = true
                sendState(using: keymap_protocol_platform_get_snapshot())
            case .getKeymapMetadata:
                isConnected = true
                sendKeymapMetadata(using: keymap_protocol_platform_get_snapshot())
            case .getKeymapChunk:
                isConnected = true
                sendKeymapChunk(
                    startingAt: KeymapProtocol.uint16(from: bytes, at: 6),
                    using: keymap_protocol_platform_get_snapshot()
                )
            case .setRGBSettings:
                applyRGBSettings(from: bytes)
            case .state, .keymapMetadata, .keymapChunk:
                break
            }
        }

        /// Sends state when observable QMK state changes.
        static func performHousekeeping() {
            guard isConnected else { return }
            let snapshot = keymap_protocol_platform_get_snapshot()
            guard hasStateChanged(snapshot),
                snapshot.timestamp &- lastSendTimestamp >= minimumSendInterval
            else { return }
            sendState(using: snapshot)
        }

        /// Applies a validated host RGB request through QMK.
        fileprivate static func applyRGBSettings(from bytes: UnsafeBufferPointer<UInt8>) {
            guard KeymapProtocol.RGBEffect(rawValue: bytes[7]) != nil else { return }
            let applied = keymap_protocol_platform_apply_rgb(
                bytes[7], bytes[8], bytes[9], bytes[10],
                bytes[6] == 0 ? 0 : 1, bytes[11]
            )
            guard applied != 0 else { return }
            isConnected = true
            sendState(using: keymap_protocol_platform_get_snapshot())
        }

        /// Encodes and sends current keyboard state.
        fileprivate static func sendState(using snapshot: keymap_protocol_platform_snapshot_t) {
            let includesRGBSettings = snapshot.includes_rgb_settings != 0
                && KeymapProtocol.RGBEffect(rawValue: snapshot.rgb_effect_index) != nil
            sequence &+= 1
            var report: [32 of UInt8] = .init(repeating: 0)
            let encoded = withUnsafeMutableBytes(of: &report) { rawBytes in
                KeymapProtocol.encodeStateReport(
                    to: rawBytes.bindMemory(to: UInt8.self),
                    layoutID: snapshot.layout_id,
                    layerStateMask: snapshot.layer_state_mask,
                    defaultLayerStateMask: snapshot.default_layer_state_mask,
                    sequence: sequence,
                    includesRGBSettings: includesRGBSettings,
                    rgbEffect: includesRGBSettings ? snapshot.rgb_effect_index : 0,
                    rgbHue: snapshot.rgb_hue,
                    rgbSaturation: snapshot.rgb_saturation,
                    rgbBrightness: snapshot.rgb_brightness,
                    isRGBEnabled: snapshot.is_rgb_enabled != 0,
                    rgbSpeed: snapshot.rgb_speed
                )
            }
            guard encoded else { return }
            send(&report)
            recordSentState(snapshot)
        }

        /// Encodes and sends dimensions and fingerprints.
        fileprivate static func sendKeymapMetadata(
            using snapshot: keymap_protocol_platform_snapshot_t
        ) {
            guard let entryCount = entryCount(for: snapshot) else { return }
            let fingerprint = fingerprint(for: snapshot, entryCount: entryCount)
            var report: [32 of UInt8] = .init(repeating: 0)
            let encoded = withUnsafeMutableBytes(of: &report) { rawBytes in
                KeymapProtocol.encodeKeymapMetadataReport(
                    to: rawBytes.bindMemory(to: UInt8.self),
                    layoutID: snapshot.layout_id,
                    layerCount: snapshot.layer_count,
                    matrixRowCount: snapshot.matrix_row_count,
                    matrixColumnCount: snapshot.matrix_column_count,
                    fingerprint: fingerprint,
                    semanticFingerprint: snapshot.semantic_fingerprint,
                    styleFingerprint: snapshot.style_fingerprint,
                    entryCount: entryCount,
                    encoderCount: snapshot.encoder_count
                )
            }
            guard encoded else { return }
            send(&report)
        }

        /// Encodes and sends one page of compiled keymap entries.
        fileprivate static func sendKeymapChunk(
            startingAt startIndex: UInt16,
            using snapshot: keymap_protocol_platform_snapshot_t
        ) {
            guard let totalEntryCount = entryCount(for: snapshot), startIndex < totalEntryCount else {
                return
            }
            let count = UInt8(min(Int(totalEntryCount - startIndex), KeymapProtocol.entriesPerChunk))
            var report: [32 of UInt8] = .init(repeating: 0)
            let encoded = withUnsafeMutableBytes(of: &report) { rawBytes -> Bool in
                let bytes = rawBytes.bindMemory(to: UInt8.self)
                guard KeymapProtocol.encodeKeymapChunkHeader(
                    to: bytes,
                    layoutID: snapshot.layout_id,
                    entryCount: count,
                    startIndex: startIndex,
                    totalEntryCount: totalEntryCount
                ) else { return false }
                for chunkIndex in 0..<count {
                    let entry = keymap_protocol_platform_get_entry(startIndex + UInt16(chunkIndex))
                    guard KeymapProtocol.encodeKeymapEntry(
                        keycode: entry.keycode,
                        semanticID: entry.semantic_id,
                        styleID: entry.style_id,
                        at: chunkIndex,
                        to: bytes
                    ) else { return false }
                }
                return true
            }
            guard encoded else { return }
            send(&report)
        }

        /// Whether current state differs from the last sent state.
        fileprivate static func hasStateChanged(
            _ snapshot: keymap_protocol_platform_snapshot_t
        ) -> Bool {
            snapshot.layer_state_mask != lastLayerState
                || snapshot.default_layer_state_mask != lastDefaultLayerState
                || snapshot.includes_rgb_settings != lastIncludesRGBSettings
                || snapshot.rgb_effect_index != lastRGBEffectIndex
                || snapshot.rgb_hue != lastRGBHue
                || snapshot.rgb_saturation != lastRGBSaturation
                || snapshot.rgb_brightness != lastRGBBrightness
                || snapshot.is_rgb_enabled != lastRGBEnabled
                || snapshot.rgb_speed != lastRGBSpeed
        }

        /// Records a successfully sent state.
        fileprivate static func recordSentState(
            _ snapshot: keymap_protocol_platform_snapshot_t
        ) {
            lastSendTimestamp = snapshot.timestamp
            lastLayerState = snapshot.layer_state_mask
            lastDefaultLayerState = snapshot.default_layer_state_mask
            lastIncludesRGBSettings = snapshot.includes_rgb_settings
            lastRGBEffectIndex = snapshot.rgb_effect_index
            lastRGBHue = snapshot.rgb_hue
            lastRGBSaturation = snapshot.rgb_saturation
            lastRGBBrightness = snapshot.rgb_brightness
            lastRGBEnabled = snapshot.is_rgb_enabled
            lastRGBSpeed = snapshot.rgb_speed
        }

        /// Passes one fixed-size stack report to QMK.
        fileprivate static func send(_ report: inout [32 of UInt8]) {
            withUnsafeMutableBytes(of: &report) { rawBytes in
                guard let baseAddress = rawBytes.baseAddress else { return }
                keymap_protocol_platform_send(
                    baseAddress.assumingMemoryBound(to: UInt8.self),
                    UInt8(rawBytes.count)
                )
            }
        }
    }
#endif
