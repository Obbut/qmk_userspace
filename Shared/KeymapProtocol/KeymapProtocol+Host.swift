// Desktop conveniences built on the embedded-ready protocol definition.
// SPDX-License-Identifier: GPL-2.0-or-later

#if !hasFeature(Embedded)
    /// Host-side validation and decoding for protocol-v5 reports.
    extension KeymapProtocol {
        /// Creates a request for the keyboard's current state.
        ///
        /// - Returns: One complete Raw HID output report.
        public static func makeStateRequest() -> [UInt8] {
            makeRequest(type: .getState)
        }

        /// Creates a request for keymap dimensions and metadata fingerprints.
        ///
        /// - Returns: One complete Raw HID output report.
        public static func makeKeymapMetadataRequest() -> [UInt8] {
            makeRequest(type: .getKeymapMetadata)
        }

        /// Creates a request for the most recent retained crash record.
        public static func makeCrashReportRequest() -> [UInt8] {
            makeRequest(type: .getCrashReport)
        }

        /// Acknowledges successful durable persistence of the crash record.
        public static func makeClearCrashReportRequest() -> [UInt8] {
            makeRequest(type: .clearCrashReport)
        }

        /// Creates a request for consecutive keymap entries.
        ///
        /// - Parameter startIndex: The first layer-major matrix entry to return.
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

        /// Creates a deliberately confirmed request to restart into the hardware bootloader.
        ///
        /// - Returns: One complete Raw HID output report.
        public static func makeBootloaderRequest() -> [UInt8] {
            var report = makeRequest(type: .enterBootloader)
            report.withUnsafeMutableBufferPointer {
                writeUInt32(bootloaderConfirmation, to: $0, at: 6)
            }
            return report
        }

        /// Returns whether a packet acknowledges an accepted bootloader request.
        ///
        /// - Parameter bytes: One complete Raw HID input report.
        public static func isBootloaderAcknowledgement(_ bytes: [UInt8]) -> Bool {
            bytes.withUnsafeBufferPointer {
                hasValidHeader(in: $0, messageType: .bootloaderAcknowledgement)
                    && uint32(from: $0, at: 6) == bootloaderConfirmation
            }
        }

        /// Returns state decoded from a Raw HID packet.
        ///
        /// - Parameter bytes: A complete Raw HID input report.
        /// - Returns: A validated state report, or `nil` for another protocol or version.
        public static func stateReport(from bytes: [UInt8]) -> KeyboardStateReport? {
            bytes.withUnsafeBufferPointer { report in
                guard hasValidHeader(in: report, messageType: .state) else { return nil }

                let capabilities = uint32(from: report, at: 22)
                let rgbSettings: RGBSettings?
                if capabilities & rgbSettingsCapability != 0,
                    let effect = RGBEffect(rawValue: report[26])
                {
                    rgbSettings = RGBSettings(
                        isEnabled: report[30] != 0,
                        effect: effect,
                        hue: report[27],
                        saturation: report[28],
                        brightness: min(report[29], RGBSettings.maximumBrightness),
                        speed: report[31]
                    )
                } else {
                    rgbSettings = nil
                }

                return KeyboardStateReport(
                    layoutID: LayoutID(rawValue: uint32(from: report, at: 6)),
                    layerStateMask: uint32(from: report, at: 10),
                    defaultLayerStateMask: uint32(from: report, at: 14),
                    sequence: uint32(from: report, at: 18),
                    capabilities: capabilities,
                    rgbSettings: rgbSettings
                )
            }
        }

        /// Returns a firmware-authorized layer-HUD trigger decoded from Raw HID.
        ///
        /// - Parameter bytes: A complete Raw HID input report.
        /// - Returns: A validated layer-HUD trigger, or `nil` for another packet type.
        public static func layerHUDTrigger(from bytes: [UInt8]) -> LayerHUDTrigger? {
            bytes.withUnsafeBufferPointer { report in
                guard hasValidHeader(in: report, messageType: .layerHUDTrigger) else {
                    return nil
                }
                return LayerHUDTrigger(
                    layoutID: LayoutID(rawValue: uint32(from: report, at: 6)),
                    layerStateMask: uint32(from: report, at: 10),
                    defaultLayerStateMask: uint32(from: report, at: 14)
                )
            }
        }

        /// Returns a validated retained crash record from a Raw HID packet.
        public static func crashReport(from bytes: [UInt8]) -> CrashReport? {
            bytes.withUnsafeBufferPointer { report in
                let flags = report.count > 8 ? report[8] : 0
                let guardFlags = flags & 0x06
                guard hasValidHeader(in: report, messageType: .crashReport),
                    let reason = CrashReason(rawValue: report[6]),
                    let phase = CrashPhase(rawValue: report[7]),
                    flags & ~0x1F == 0,
                    guardFlags != 0x06,
                    (flags & 0x08 == 0 && guardFlags == 0)
                        || (flags & 0x08 != 0 && (guardFlags == 0x02 || guardFlags == 0x04)),
                    report[9] > 0 || reason == .powerOnOrBrownout || reason == .unknown
                else { return nil }
                return CrashReport(
                    reason: reason,
                    phase: phase,
                    flags: flags,
                    consecutiveFailures: report[9],
                    buildID: uint32(from: report, at: 10),
                    uptime: uint32(from: report, at: 14),
                    programCounter: uint32(from: report, at: 18),
                    linkRegister: uint32(from: report, at: 22),
                    stackPointer: uint32(from: report, at: 26),
                    stackFree: uint16(from: report, at: 30)
                )
            }
        }

        /// Returns keymap metadata decoded from a Raw HID packet.
        ///
        /// - Parameter bytes: A complete Raw HID input report.
        /// - Returns: Validated transfer metadata, or `nil` for another packet type.
        public static func keymapMetadataReport(from bytes: [UInt8]) -> KeymapMetadataReport? {
            bytes.withUnsafeBufferPointer { report in
                guard hasValidHeader(in: report, messageType: .keymapMetadata) else { return nil }

                let layerCount = Int(report[10])
                let matrixRowCount = Int(report[11])
                let matrixColumnCount = Int(report[12])
                let entrySize = Int(report[13])
                let chunkEntryCount = Int(report[14])
                let encoderCount = Int(report[15])
                let entryCount = Int(uint16(from: report, at: 16))
                let directionCount = Int(report[30])
                let matrixEntryCount = layerCount * matrixRowCount * matrixColumnCount
                let encoderEntryCount = layerCount * encoderCount * directionCount
                guard layerCount > 0,
                    layerCount <= 32,
                    matrixRowCount > 0,
                    matrixColumnCount > 0,
                    directionCount == Int(encoderDirectionCount),
                    entrySize == keymapEntrySize,
                    chunkEntryCount > 0,
                    chunkEntryCount * entrySize <= reportSize - keymapChunkOffset,
                    entryCount == matrixEntryCount + encoderEntryCount
                else {
                    return nil
                }

                return KeymapMetadataReport(
                    layoutID: LayoutID(rawValue: uint32(from: report, at: 6)),
                    layerCount: layerCount,
                    matrixRowCount: matrixRowCount,
                    matrixColumnCount: matrixColumnCount,
                    entryByteCount: entrySize,
                    entriesPerChunk: chunkEntryCount,
                    fingerprint: uint32(from: report, at: 18),
                    legendFingerprint: uint32(from: report, at: 22),
                    styleFingerprint: uint32(from: report, at: 26),
                    entryCount: entryCount,
                    encoderCount: encoderCount
                )
            }
        }

        /// Returns a keymap chunk decoded from a Raw HID packet.
        ///
        /// - Parameter bytes: A complete Raw HID input report.
        /// - Returns: A validated page, or `nil` for another or malformed packet.
        public static func keymapChunkReport(from bytes: [UInt8]) -> KeymapChunkReport? {
            bytes.withUnsafeBufferPointer { report in
                guard hasValidHeader(in: report, messageType: .keymapChunk) else { return nil }

                let count = Int(report[14])
                let startIndex = Int(uint16(from: report, at: 10))
                let totalEntryCount = Int(uint16(from: report, at: 12))
                guard count > 0,
                    count <= entriesPerChunk,
                    keymapChunkOffset + count * keymapEntrySize <= reportSize,
                    startIndex + count <= totalEntryCount
                else {
                    return nil
                }

                var entries: [FirmwareKeymapEntry] = []
                entries.reserveCapacity(count)
                for entryIndex in 0..<count {
                    let offset = keymapChunkOffset + entryIndex * keymapEntrySize
                    entries.append(
                        FirmwareKeymapEntry(
                            keycode: uint16(from: report, at: offset),
                            legendID: LegendID(rawValue: uint16(from: report, at: offset + 2)),
                            styleID: StyleID(rawValue: uint16(from: report, at: offset + 4))
                        )
                    )
                }
                return KeymapChunkReport(
                    layoutID: LayoutID(rawValue: uint32(from: report, at: 6)),
                    startIndex: startIndex,
                    totalEntryCount: totalEntryCount,
                    entries: entries
                )
            }
        }

        /// Creates a zero-filled request with the shared envelope.
        ///
        /// - Parameter type: The host-to-firmware message type.
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
