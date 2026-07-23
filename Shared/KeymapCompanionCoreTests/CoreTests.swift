import Foundation
import Dependencies
import ObbutKeyboardCatalog
import ObbutKeymaps
import Testing
@testable import KeymapCompanionCore

/// Verifies host requests accept only the protocol-v5 envelope.
@Test
func protocolRequestsUseVersionFiveEnvelope() {
    let request = KeymapProtocol.makeKeymapMetadataRequest()

    #expect(request.count == KeymapProtocol.reportSize)
    #expect(Array(request.prefix(4)) == Array("KMAP".utf8))
    #expect(request[4] == 5)
    #expect(request[5] == 3)

    let crashRequest = KeymapProtocol.makeCrashReportRequest()
    let clearRequest = KeymapProtocol.makeClearCrashReportRequest()
    #expect(crashRequest.count == KeymapProtocol.reportSize)
    #expect(crashRequest[5] == 10)
    #expect(clearRequest.count == KeymapProtocol.reportSize)
    #expect(clearRequest[5] == 12)
}

/// Verifies bootloader entry requires the protocol's complete confirmation token.
@Test
func bootloaderRequestIsDeliberateAndAcknowledged() {
    let request = KeymapProtocol.makeBootloaderRequest()
    #expect(request.count == KeymapProtocol.reportSize)
    #expect(Array(request.prefix(6)) == [0x4B, 0x4D, 0x41, 0x50, 5, 8])
    #expect(Array(request[6..<10]) == Array("DFU!".utf8))

    var acknowledgement = [UInt8](repeating: 0, count: KeymapProtocol.reportSize)
    acknowledgement.withUnsafeMutableBufferPointer {
        #expect(KeymapProtocol.encodeBootloaderAcknowledgement(to: $0))
    }
    #expect(KeymapProtocol.isBootloaderAcknowledgement(acknowledgement))
    acknowledgement[6] = 0
    #expect(!KeymapProtocol.isBootloaderAcknowledgement(acknowledgement))
}

/// Verifies the fixed 26-byte crash payload round-trips without padding.
@Test
func crashReportRoundTripsAndRejectsMalformedPackets() {
    let crash = CrashReport(
        reason: .hardFault,
        phase: .pointingTask,
        flags: 0x0B,
        consecutiveFailures: 2,
        buildID: 0x1234_5678,
        uptime: 9_876,
        programCounter: 0x1000_1235,
        linkRegister: 0x1000_4567,
        stackPointer: 0x2004_0B00,
        stackFree: 321
    )
    var packet = [UInt8](repeating: 0, count: KeymapProtocol.reportSize)
    #expect(packet.withUnsafeMutableBufferPointer {
        KeymapProtocol.encodeCrashReport(to: $0, report: crash)
    })
    #expect(packet[5] == 11)
    #expect(KeymapProtocol.crashReport(from: packet) == crash)

    var session = KeymapTransferSession()
    #expect(session.receive(packet) == [.crashReport(crash)])

    packet[7] = 0xFF
    #expect(KeymapProtocol.crashReport(from: packet) == nil)
    packet[7] = CrashPhase.pointingTask.rawValue
    packet[8] = 0x0F
    #expect(KeymapProtocol.crashReport(from: packet) == nil)
    packet[8] = crash.flags
    packet[9] = 0
    #expect(KeymapProtocol.crashReport(from: packet) == nil)
    packet.removeLast()
    #expect(KeymapProtocol.crashReport(from: packet) == nil)
}

/// Verifies persistence is structured and append-only before acknowledgement.
@Test
func crashReportPersistenceAppendsStructuredEntries() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("CrashReportLogTests-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    let report = CrashReport(
        reason: .watchdog,
        phase: .protocolHousekeeping,
        flags: 8,
        consecutiveFailures: 1,
        buildID: 7,
        uptime: 8,
        programCounter: 0,
        linkRegister: 0,
        stackPointer: 9,
        stackFree: 10
    )
    try CrashReportLog.persist(report, in: directory)
    try CrashReportLog.persist(report, in: directory)
    let data = try Data(contentsOf: directory.appendingPathComponent("firmware-crashes.jsonl"))
    let lines = String(decoding: data, as: UTF8.self).split(separator: "\n")
    #expect(lines.count == 2)
    #expect(lines.allSatisfy { $0.contains("\"buildID\":7") })
    #expect(lines.allSatisfy { $0.contains("\"recordedAt\"") })
}

/// Verifies every catalogued keyboard produces valid renderer input.
@Test
func allCatalogKeyboardsProduceRendererDocuments() {
    #expect(ObbutKeyboardCatalog.all.count == 4)
    for firmware in ObbutKeyboardCatalog.all {
        let definition = KeymapDefinition.makePreview(for: LayoutID(rawValue: firmware.layoutID))
        #expect(definition.positionedKeys.count == firmware.layout.keys.count)
        #expect(definition.supportedLayers.count == firmware.layers.count)
        #expect(definition.encoders.count == firmware.layout.encoders.count)
        #expect(definition.legendsMatch)
        #expect(definition.stylesMatch)
    }
}

/// Verifies source metadata receives deterministic, collision-free wire identifiers.
@Test
func generatedMetadataUsesDeterministicWireIdentifiers() {
    for firmware in ObbutKeyboardCatalog.all {
        let legendIDs = firmware.legends.map(\.id)
        let styleIDs = firmware.styles.map(\.id)

        #expect(legendIDs.allSatisfy { $0 != 0 })
        #expect(Set(legendIDs).count == legendIDs.count)
        #expect(styleIDs.first == 0)
        #expect(styleIDs.dropFirst().allSatisfy { $0 != 0 })
        #expect(Set(styleIDs).count == styleIDs.count)
    }
}

/// Verifies a metadata mismatch preserves the keymap and exposes diagnostics.
@Test
func metadataMismatchDoesNotDiscardKeymap() throws {
    let keymap = TestKeymaps.makeKyria(
        legendFingerprint: 0xDEAD_BEEF,
        styleFingerprint: 0xFEED_FACE,
        legendID: LegendID(rawValue: 999),
        styleID: StyleID(rawValue: 999)
    )
    let definition = try #require(KeymapDefinition(firmwareKeymap: keymap))

    #expect(!definition.legendsMatch)
    #expect(!definition.stylesMatch)
    let legend = try #require(definition.positionedKeys.first?.key.legends.first)
    #expect(legend.label == "Legend #999")
    #expect(!legend.style.isKnown)
}

/// Verifies automatic pointer activity never opens the transient layer HUD.
@MainActor
@Test
func pointerLayerDoesNotPresentHUD() async throws {
    let definition = KeymapDefinition.makePreview(for: .kyria)
    let pointer = try #require(definition.supportedLayers.first { $0.displayName == "Pointer" })
    let hud = LayerHUDModel(transitionDelay: .milliseconds(20))
    let mask = UInt32(1 << pointer.rawValue) | 1

    hud.update(activeLayer: pointer, activeLayerMask: mask)
    try await Task.sleep(for: .milliseconds(80))

    #expect(hud.presentation == nil)
    #expect(pointer.legendName == "P")
}

/// Verifies normalized RGB controls clamp and round to firmware byte ranges.
@Test
func normalizedRGBControlsClampToFirmwareRanges() {
    var settings = RGBSettings.default
    settings.normalizedBrightness = 0.5
    settings.normalizedSpeed = 0.75

    #expect(settings.brightness == 64)
    #expect(settings.speed == 191)
    #expect(settings.normalizedBrightness == 0.5)
    #expect(abs(settings.normalizedSpeed - 0.75) < 0.002)
}

/// Verifies protocol v5 transfers support a keymap with no encoders.
@Test
func transferSessionPublishesZeroEncoderKeymap() {
    let layoutID = UInt32(0x1234_5678)
    let keycode = UInt16(0x0004)
    var fingerprint = KeymapProtocol.fingerprintSeed(
        layoutID: layoutID,
        layerCount: 1,
        matrixRowCount: 1,
        matrixColumnCount: 1,
        encoderCount: 0
    )
    fingerprint = KeymapProtocol.fingerprint(
        afterAddingKeycode: keycode,
        legendID: 0,
        styleID: 0,
        to: fingerprint
    )

    var metadata = [UInt8](repeating: 0, count: KeymapProtocol.reportSize)
    metadata.withUnsafeMutableBufferPointer { bytes in
        #expect(
            KeymapProtocol.encodeKeymapMetadataReport(
                to: bytes,
                layoutID: layoutID,
                layerCount: 1,
                matrixRowCount: 1,
                matrixColumnCount: 1,
                fingerprint: fingerprint,
                legendFingerprint: 11,
                styleFingerprint: 22,
                entryCount: 1,
                encoderCount: 0
            )
        )
    }
    var chunk = [UInt8](repeating: 0, count: KeymapProtocol.reportSize)
    chunk.withUnsafeMutableBufferPointer { bytes in
        #expect(
            KeymapProtocol.encodeKeymapChunkHeader(
                to: bytes,
                layoutID: layoutID,
                entryCount: 1,
                startIndex: 0,
                totalEntryCount: 1
            )
        )
        #expect(
            KeymapProtocol.encodeKeymapEntry(
                keycode: keycode,
                legendID: 0,
                styleID: 0,
                at: 0,
                to: bytes
            )
        )
    }

    var session = KeymapTransferSession()
    #expect(session.start() == [
        .write(report: KeymapProtocol.makeKeymapMetadataRequest()),
        .write(report: KeymapProtocol.makeCrashReportRequest()),
    ])
    #expect(session.receive(metadata) == [.write(report: KeymapProtocol.makeKeymapChunkRequest(startingAt: 0))])
    let completion = session.receive(chunk)

    guard case let .keymap(keymap) = completion.first else {
        Issue.record("The completed transfer did not publish its keymap.")
        return
    }
    #expect(keymap.hasValidFingerprint)
    #expect(keymap.encoderCount == 0)
    #expect(completion.last == .write(report: KeymapProtocol.makeStateRequest()))
}

/// Verifies a layer-HUD trigger round-trips its complete keyboard state snapshot.
@Test
func layerHUDTriggerRoundTripsProtocolFive() throws {
    var packet = [UInt8](repeating: 0, count: KeymapProtocol.reportSize)
    let encoded = packet.withUnsafeMutableBufferPointer {
        KeymapProtocol.encodeLayerHUDTrigger(
            to: $0,
            layoutID: LayoutID.kyria.rawValue,
            layerStateMask: 1 << 2,
            defaultLayerStateMask: 1
        )
    }
    let trigger = try #require(KeymapProtocol.layerHUDTrigger(from: packet))

    #expect(encoded)
    #expect(packet[4] == 5)
    #expect(packet[5] == 13)
    #expect(trigger.layoutID == .kyria)
    #expect(trigger.layerStateMask == 1 << 2)
    #expect(trigger.defaultLayerStateMask == 1)
    #expect(trigger.effectiveLayerMask == 5)

    packet[4] = 4
    #expect(KeymapProtocol.layerHUDTrigger(from: packet) == nil)
}

/// Verifies the transfer session discards triggers before keymap and state validation.
@Test
func transferSessionRejectsPrematureLayerHUDTrigger() {
    var packet = [UInt8](repeating: 0, count: KeymapProtocol.reportSize)
    packet.withUnsafeMutableBufferPointer {
        #expect(
            KeymapProtocol.encodeLayerHUDTrigger(
                to: $0,
                layoutID: LayoutID.kyria.rawValue,
                layerStateMask: 1 << 2,
                defaultLayerStateMask: 1
            )
        )
    }
    var session = KeymapTransferSession()

    #expect(session.receive(packet).isEmpty)
}

/// Verifies the observable model uses its injected hardware implementation.
@MainActor
@Test
func observableModelUsesInjectedHardwareClient() async throws {
    let hardware = RecordingHardwareClient()
    let model = withDependencies {
        $0.keyboardHardware = hardware
    } operation: {
        KeymapCompanionModel.makeLive()
    }

    #expect(hardware.startCount == 1)
    hardware.emit(.keymap(TestKeymaps.makeKyria()))
    hardware.emit(
        .state(
            KeyboardStateReport(
                layoutID: .kyria,
                layerStateMask: 1,
                defaultLayerStateMask: 1,
                sequence: 42,
                capabilities: KeymapProtocol.layerStateCapability
                    | KeymapProtocol.keymapReadCapability
                    | KeymapProtocol.rgbSettingsCapability,
                rgbSettings: .default
            )
        )
    )

    #expect(model.connectionStatus == .connected)
    #expect(model.layoutID == .kyria)
    #expect(model.latestSequence == 42)
    #expect(model.supportsRGBSettings)

    model.updateRGBSettings { $0.isEnabled = false }
    try await Task.sleep(for: .milliseconds(220))
    #expect(hardware.appliedRGBSettings == [model.rgbSettings])

    model.reconnect()
    #expect(hardware.restartCount == 1)
    model.shutdown()
    #expect(hardware.stopCount == 1)
}

/// Verifies only a current firmware trigger can reveal the shared HUD model.
@MainActor
@Test
func observableModelRequiresCurrentFirmwareHUDTrigger() async throws {
    let hardware = RecordingHardwareClient()
    let hud = LayerHUDModel(transitionDelay: .milliseconds(20))
    let model = withDependencies {
        $0.keyboardHardware = hardware
    } operation: {
        KeymapCompanionModel.makeLive(layerHUD: hud)
    }
    let keymap = TestKeymaps.makeKyria()
    let definition = try #require(KeymapDefinition(firmwareKeymap: keymap))
    let lower = try #require(
        definition.supportedLayers.first { $0.displayName == "Lower" }
    )
    let lowerMask = UInt32(1) << UInt32(lower.rawValue)

    hardware.emit(.keymap(keymap))
    hardware.emit(
        .state(
            KeyboardStateReport(
                layoutID: .kyria,
                layerStateMask: lowerMask,
                defaultLayerStateMask: 1,
                sequence: 1,
                capabilities: KeymapProtocol.layerStateCapability
                    | KeymapProtocol.keymapReadCapability,
                rgbSettings: nil
            )
        )
    )
    try await Task.sleep(for: .milliseconds(80))
    #expect(hud.presentation == nil)

    hardware.emit(
        .layerHUDTrigger(
            LayerHUDTrigger(
                layoutID: .kyria,
                layerStateMask: UInt32(1) << 3,
                defaultLayerStateMask: 1
            )
        )
    )
    #expect(hud.presentation == nil)

    hardware.emit(
        .layerHUDTrigger(
            LayerHUDTrigger(
                layoutID: .kyria,
                layerStateMask: lowerMask,
                defaultLayerStateMask: 1
            )
        )
    )
    #expect(hud.presentation?.layer == lower)

    hardware.emit(
        .state(
            KeyboardStateReport(
                layoutID: .kyria,
                layerStateMask: 0,
                defaultLayerStateMask: 1,
                sequence: 2,
                capabilities: KeymapProtocol.layerStateCapability
                    | KeymapProtocol.keymapReadCapability,
                rgbSettings: nil
            )
        )
    )
    #expect(hud.presentation?.layer == definition.supportedLayers.first)
    try await Task.sleep(for: .milliseconds(80))
    #expect(hud.presentation == nil)
    model.shutdown()
}
