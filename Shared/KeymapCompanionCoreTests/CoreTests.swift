import Testing
@testable import KeymapCompanionCore

/// Verifies transparent keys resolve through the complete active layer stack.
@Test
func transparentKeyResolvesThroughActiveLayerStack() {
    let key = KeymapKey(
        id: "r0c0",
        entries: [
            FirmwareKeymapEntry(keycode: 0x0009, semantic: .none, style: .standard),
            FirmwareKeymapEntry(keycode: 0x0008, semantic: .none, style: .purple),
            FirmwareKeymapEntry(keycode: 0x0001, semantic: .none, style: .standard),
            FirmwareKeymapEntry(keycode: 0x0001, semantic: .none, style: .standard),
            FirmwareKeymapEntry(keycode: 0x0001, semantic: .none, style: .standard),
        ]
    )
    let mask =
        UInt32(1 << KeymapLayer.base.rawValue)
        | UInt32(1 << KeymapLayer.qwerty.rawValue)
        | UInt32(1 << KeymapLayer.lower.rawValue)

    #expect(key.resolvedLegend(forActiveLayerMask: mask).label == "E")
    #expect(!key.isDirectlyMapped(on: .lower))
}

/// Verifies host requests use the protocol v3 signature and message identifier.
@Test
func protocolRequestsUseVersionThreeEnvelope() {
    let request = KeymapProtocol.makeKeymapMetadataRequest()

    #expect(request.count == KeymapProtocol.reportSize)
    #expect(Array(request.prefix(4)) == Array("KMAP".utf8))
    #expect(request[4] == 3)
    #expect(request[5] == 3)
}

/// Verifies each supported geometry maps every visible switch to a unique matrix position.
@Test
func supportedGeometryMapsVisibleSwitchesToUniqueMatrixPositions() {
    #expect(KeyboardGeometryCatalog.kyria.placements.count == 50)
    #expect(KeyboardGeometryCatalog.elora.placements.count == 62)
    #expect(Set(KeyboardGeometryCatalog.kyria.matrixPositions).count == 50)
    #expect(Set(KeyboardGeometryCatalog.elora.matrixPositions).count == 62)
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

/// Verifies a fingerprint-validated transfer publishes its complete keymap.
@Test
func transferSessionPublishesFingerprintValidatedKeymap() {
    let keyboardKind = KeymapProtocol.KeyboardKind.kyria.rawValue
    let keycode: UInt16 = 0x0004
    let semantic = KeySemantic.none
    let style = KeymapProtocol.KeyStyle.standard.rawValue
    var fingerprint = KeymapProtocol.fingerprintSeed(
        keyboardKind: keyboardKind,
        layerCount: 1,
        matrixRowCount: 1,
        matrixColumnCount: 1,
        encoderCount: 1
    )
    for _ in 0..<3 {
        fingerprint = KeymapProtocol.fingerprint(
            afterAddingKeycode: keycode,
            semantic: semantic.rawValue,
            style: style,
            to: fingerprint
        )
    }

    var metadata = [UInt8](repeating: 0, count: KeymapProtocol.reportSize)
    metadata.withUnsafeMutableBufferPointer { bytes in
        #expect(
            KeymapProtocol.encodeKeymapMetadataReport(
                to: bytes,
                keyboardKind: keyboardKind,
                layerCount: 1,
                matrixRowCount: 1,
                matrixColumnCount: 1,
                fingerprint: fingerprint,
                entryCount: 3,
                encoderCount: 1
            ))
    }
    var chunk = [UInt8](repeating: 0, count: KeymapProtocol.reportSize)
    chunk.withUnsafeMutableBufferPointer { bytes in
        #expect(
            KeymapProtocol.encodeKeymapChunkHeader(
                to: bytes,
                keyboardKind: keyboardKind,
                entryCount: 3,
                startIndex: 0,
                totalEntryCount: 3
            ))
        for index in 0..<3 {
            #expect(
                KeymapProtocol.encodeKeymapEntry(
                    keycode: keycode,
                    semantic: semantic.rawValue,
                    style: style,
                    at: UInt8(index),
                    to: bytes
                ))
        }
    }

    var session = KeymapTransferSession()
    #expect(session.start() == [.write(report: KeymapProtocol.makeKeymapMetadataRequest())])
    #expect(
        session.receive(metadata) == [
            .write(report: KeymapProtocol.makeKeymapChunkRequest(startingAt: 0))
        ])

    let completion = session.receive(chunk)
    #expect(completion.count == 2)
    guard case let .keymap(keymap) = completion.first else {
        Issue.record("The completed transfer did not publish its keymap.")
        return
    }
    #expect(keymap.hasValidFingerprint)
    #expect(
        keymap.entries
            == Array(
                repeating: FirmwareKeymapEntry(keycode: keycode, semantic: semantic, style: .standard),
                count: 3
            ))
    #expect(completion.last == .write(report: KeymapProtocol.makeStateRequest()))
}

/// Verifies the observable model uses its injected hardware implementation.
@MainActor
@Test
func observableModelUsesInjectedHardwareClient() async throws {
    let hardware = RecordingHardwareClient()
    let model = KeymapCompanionModel.makeLive(hardware: hardware)

    #expect(hardware.startCount == 1)
    #expect(model.connectionStatus == .searching)

    hardware.emit(.keymap(TestKeymaps.makeKyria()))
    hardware.emit(
        .state(
            KeyboardStateReport(
                keyboardKind: .kyria,
                layerStateMask: 1,
                defaultLayerStateMask: 1,
                sequence: 42,
                capabilities: KeymapProtocol.layerStateCapability
                    | KeymapProtocol.keymapReadCapability
                    | KeymapProtocol.rgbSettingsCapability,
                rgbSettings: .default
            )))

    #expect(model.connectionStatus == .connected)
    #expect(model.keyboardKind == .kyria)
    #expect(model.latestSequence == 42)
    #expect(model.supportsRGBSettings)

    model.updateRGBSettings { $0.isEnabled = false }
    try await Task.sleep(for: .milliseconds(220))
    #expect(hardware.appliedRGBSettings == [model.rgbSettings])

    model.reconnect()
    #expect(hardware.restartCount == 1)
    #expect(model.connectionStatus == .searching)

    model.shutdown()
    #expect(hardware.stopCount == 1)
}

/// Verifies the shared HUD publishes a presentation only after its dwell delay.
@MainActor
@Test
func sharedHUDModelPublishesAfterLayerDwell() async throws {
    let hud = LayerHUDModel(transitionDelay: .milliseconds(20))
    let mask =
        UInt32(1 << KeymapLayer.base.rawValue)
        | UInt32(1 << KeymapLayer.lower.rawValue)

    hud.update(activeLayer: .lower, activeLayerMask: mask)
    #expect(hud.presentation == nil)
    try await Task.sleep(for: .milliseconds(80))
    #expect(hud.presentation == LayerHUDPresentation(layer: .lower, activeLayerMask: mask))
}
