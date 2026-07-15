// Desktop conveniences built on the embedded-ready protocol definition.
// SPDX-License-Identifier: GPL-2.0-or-later

#if !hasFeature(Embedded)
    /// Host-side validation and decoding for protocol reports.
    extension KeymapProtocol {
        /// Creates a request for the keyboard's current state.
        ///
        /// - Returns: One complete Raw HID output report.
        public static func makeStateRequest() -> [UInt8] {
            makeRequest(type: .getState)
        }

        /// Creates a request for the firmware's keymap dimensions and fingerprint.
        ///
        /// - Returns: One complete Raw HID output report.
        public static func makeKeymapMetadataRequest() -> [UInt8] {
            makeRequest(type: .getKeymapMetadata)
        }

        /// Creates a request for consecutive keymap entries.
        ///
        /// - Parameter startIndex: The first layer-major matrix entry to return.
        ///
        /// - Returns: One complete Raw HID output report.
        public static func makeKeymapChunkRequest(startingAt startIndex: UInt16) -> [UInt8] {
            var report = makeRequest(type: .getKeymapChunk)
            report.withUnsafeMutableBufferPointer {
                writeUInt16(startIndex, to: $0, at: 6)
            }
            return report
        }

        /// Creates a request that persists an explicit RGB Matrix configuration.
        ///
        /// - Parameter settings: The complete base-layer configuration to apply.
        ///
        /// - Returns: One complete Raw HID output report.
        public static func makeRGBSettingsRequest(applying settings: RGBSettings) -> [UInt8] {
            var report = makeRequest(type: .setRGBSettings)
            report[6] = settings.isEnabled ? 1 : 0
            report[7] = settings.effect.rawValue
            report[8] = settings.hue
            report[9] = settings.saturation
            report[10] = min(settings.brightness, RGBSettings.maximumBrightness)
            report[11] = settings.speed
            return report
        }

        /// Returns state decoded from a Raw HID packet.
        ///
        /// - Parameter bytes: A complete Raw HID input report.
        ///
        /// - Returns: A validated state report, or `nil` for another protocol or version.
        public static func stateReport(from bytes: [UInt8]) -> KeyboardStateReport? {
            bytes.withUnsafeBufferPointer { report in
                guard hasValidHeader(in: report, messageType: .state),
                    let keyboardKind = KeyboardKind(rawValue: report[6])
                else {
                    return nil
                }

                let capabilities = uint32(from: report, at: 20)
                let rgbSettings: RGBSettings?
                if capabilities & rgbSettingsCapability != 0,
                    let effect = RGBEffect(rawValue: report[24])
                {
                    rgbSettings = RGBSettings(
                        isEnabled: report[28] != 0,
                        effect: effect,
                        hue: report[25],
                        saturation: report[26],
                        brightness: min(report[27], RGBSettings.maximumBrightness),
                        speed: report[29]
                    )
                } else {
                    rgbSettings = nil
                }

                return KeyboardStateReport(
                    keyboardKind: keyboardKind,
                    layerStateMask: uint32(from: report, at: 8),
                    defaultLayerStateMask: uint32(from: report, at: 12),
                    sequence: uint32(from: report, at: 16),
                    capabilities: capabilities,
                    rgbSettings: rgbSettings
                )
            }
        }

        /// Returns keymap metadata decoded from a Raw HID packet.
        ///
        /// - Parameter bytes: A complete Raw HID input report.
        ///
        /// - Returns: Validated transfer metadata, or `nil` for another packet type.
        public static func keymapMetadataReport(from bytes: [UInt8]) -> KeymapMetadataReport? {
            bytes.withUnsafeBufferPointer { report in
                guard hasValidHeader(in: report, messageType: .keymapMetadata),
                    let keyboardKind = KeyboardKind(rawValue: report[6])
                else {
                    return nil
                }

                let layerCount = Int(report[7])
                let matrixRowCount = Int(report[8])
                let matrixColumnCount = Int(report[9])
                let entrySize = Int(report[10])
                let chunkEntryCount = Int(report[11])
                let entryCount = Int(uint16(from: report, at: 16))
                let encoderCount = Int(report[18])
                let directionCount = Int(report[19])
                let matrixEntryCount = layerCount * matrixRowCount * matrixColumnCount
                let encoderEntryCount = layerCount * encoderCount * directionCount
                guard layerCount > 0,
                    layerCount <= 32,
                    matrixRowCount > 0,
                    matrixColumnCount > 0,
                    encoderCount > 0,
                    encoderCount <= 8,
                    directionCount == Int(encoderDirectionCount),
                    entrySize == keymapEntrySize,
                    chunkEntryCount > 0,
                    chunkEntryCount * entrySize <= reportSize - keymapChunkOffset,
                    entryCount == matrixEntryCount + encoderEntryCount
                else {
                    return nil
                }

                return KeymapMetadataReport(
                    keyboardKind: keyboardKind,
                    layerCount: layerCount,
                    matrixRowCount: matrixRowCount,
                    matrixColumnCount: matrixColumnCount,
                    entryByteCount: entrySize,
                    entriesPerChunk: chunkEntryCount,
                    fingerprint: uint32(from: report, at: 12),
                    entryCount: entryCount,
                    encoderCount: encoderCount
                )
            }
        }

        /// Returns a keymap chunk decoded from a Raw HID packet.
        ///
        /// - Parameter bytes: A complete Raw HID input report.
        ///
        /// - Returns: A validated page, or `nil` for another or malformed packet.
        public static func keymapChunkReport(from bytes: [UInt8]) -> KeymapChunkReport? {
            bytes.withUnsafeBufferPointer { report in
                guard hasValidHeader(in: report, messageType: .keymapChunk),
                    let keyboardKind = KeyboardKind(rawValue: report[6])
                else {
                    return nil
                }

                let count = Int(report[7])
                let startIndex = Int(uint16(from: report, at: 8))
                let totalEntryCount = Int(uint16(from: report, at: 10))
                guard count > 0,
                    keymapChunkOffset + count * keymapEntrySize <= reportSize,
                    startIndex + count <= totalEntryCount
                else {
                    return nil
                }

                var entries: [FirmwareKeymapEntry] = []
                entries.reserveCapacity(count)
                for entryIndex in 0..<count {
                    let offset = keymapChunkOffset + entryIndex * keymapEntrySize
                    guard let semantic = KeySemantic(rawValue: report[offset + 2]),
                        let style = KeyStyle(rawValue: report[offset + 3])
                    else { return nil }
                    entries.append(
                        FirmwareKeymapEntry(
                            keycode: uint16(from: report, at: offset),
                            semantic: semantic,
                            style: style
                        )
                    )
                }
                return KeymapChunkReport(
                    keyboardKind: keyboardKind,
                    startIndex: startIndex,
                    totalEntryCount: totalEntryCount,
                    entries: entries
                )
            }
        }

        /// Creates a zero-filled request with the shared envelope.
        ///
        /// - Parameter type: The host-to-firmware message type.
        ///
        /// - Returns: One complete output report.
        private static func makeRequest(type: MessageType) -> [UInt8] {
            var report = [UInt8](repeating: 0, count: reportSize)
            _ = report.withUnsafeMutableBufferPointer {
                initializeReport($0, as: type)
            }
            return report
        }
    }
#endif
