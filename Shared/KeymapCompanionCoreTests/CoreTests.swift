import ObbutKeyboardCatalog
import ObbutKeymaps
import Testing
@testable import KeymapCompanionCore

/// Verifies host requests accept only the protocol-v4 envelope.
@Test
func protocolRequestsUseVersionFourEnvelope() {
    let request = KeymapProtocol.makeKeymapMetadataRequest()

    #expect(request.count == KeymapProtocol.reportSize)
    #expect(Array(request.prefix(4)) == Array("KMAP".utf8))
    #expect(request[4] == 4)
    #expect(request[5] == 3)
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
        #expect(definition.semanticsMatch)
        #expect(definition.stylesMatch)
    }
}

/// Verifies source metadata receives compact wire identifiers automatically.
@Test
func generatedMetadataUsesCompactWireIdentifiers() {
    for firmware in ObbutKeyboardCatalog.all {
        #expect(firmware.semantics.map(\.id) == Array(1...UInt16(firmware.semantics.count)))
        #expect(firmware.styles.map(\.id) == Array(0..<UInt16(firmware.styles.count)))
    }
}

/// Verifies a metadata mismatch preserves the keymap and exposes diagnostics.
@Test
func metadataMismatchDoesNotDiscardKeymap() throws {
    let keymap = TestKeymaps.makeKyria(
        semanticFingerprint: 0xDEAD_BEEF,
        styleFingerprint: 0xFEED_FACE,
        semanticID: SemanticID(rawValue: 999),
        styleID: StyleID(rawValue: 999)
    )
    let definition = try #require(KeymapDefinition(firmwareKeymap: keymap))

    #expect(!definition.semanticsMatch)
    #expect(!definition.stylesMatch)
    let legend = try #require(definition.positionedKeys.first?.key.legends.first)
    #expect(legend.label == "Semantic #999")
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

/// Verifies protocol v4 transfers support a keymap with no encoders.
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
        semanticID: 0,
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
                semanticFingerprint: 11,
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
                semanticID: 0,
                styleID: 0,
                at: 0,
                to: bytes
            )
        )
    }

    var session = KeymapTransferSession()
    #expect(session.start() == [.write(report: KeymapProtocol.makeKeymapMetadataRequest())])
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

/// Verifies the observable model uses its injected hardware implementation.
@MainActor
@Test
func observableModelUsesInjectedHardwareClient() async throws {
    let hardware = RecordingHardwareClient()
    let model = KeymapCompanionModel.makeLive(hardware: hardware)

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
