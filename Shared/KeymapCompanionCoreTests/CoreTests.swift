import Testing
@testable import KeymapCompanionCore

@Test
func transparentKeyResolvesThroughActiveLayerStack() throws {
    let key = KeymapKey(
        id: "r0c0",
        entries: [
            FirmwareKeymapEntry(keycode: 0x0009, semantic: 0, style: .standard),
            FirmwareKeymapEntry(keycode: 0x0008, semantic: 0, style: .purple),
            FirmwareKeymapEntry(keycode: 0x0001, semantic: 0, style: .standard),
            FirmwareKeymapEntry(keycode: 0x0001, semantic: 0, style: .standard),
            FirmwareKeymapEntry(keycode: 0x0001, semantic: 0, style: .standard)
        ]
    )
    let mask = UInt32(1 << KeymapLayer.base.rawValue)
        | UInt32(1 << KeymapLayer.qwerty.rawValue)
        | UInt32(1 << KeymapLayer.lower.rawValue)

    #expect(key.resolvedLegend(activeLayerMask: mask).label == "E")
    #expect(!key.isDirectlyMapped(on: .lower))
}

@Test
func protocolRequestsUseVersionThreeEnvelope() {
    let request = KeymapProtocol.makeKeymapMetadataRequest()

    #expect(request.count == KeymapProtocol.reportSize)
    #expect(Array(request.prefix(4)) == Array("KMAP".utf8))
    #expect(request[4] == 3)
    #expect(request[5] == 3)
}

@Test
func rendererGeometryMatchesSupportedBoards() {
    #expect(KeyboardGeometryCatalog.kyria.placements.count == 50)
    #expect(KeyboardGeometryCatalog.elora.placements.count == 62)
    #expect(Set(KeyboardGeometryCatalog.kyria.matrixPositions).count == 50)
    #expect(Set(KeyboardGeometryCatalog.elora.matrixPositions).count == 62)
}

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

@Test
func transferSessionPublishesOnlyAFingerprintValidatedKeymap() throws {
    let keyboardKind = KeymapProtocol.KeyboardKind.kyria.rawValue
    let keycode: UInt16 = 0x0004
    let semantic = KeymapProtocol.KeySemantic.none.rawValue
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
            semantic: semantic,
            style: style,
            to: fingerprint
        )
    }

    var metadata = [UInt8](repeating: 0, count: KeymapProtocol.reportSize)
    metadata.withUnsafeMutableBufferPointer { bytes in
        #expect(KeymapProtocol.encodeKeymapMetadataReport(
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
        #expect(KeymapProtocol.encodeKeymapChunkHeader(
            to: bytes,
            keyboardKind: keyboardKind,
            entryCount: 3,
            startIndex: 0,
            totalEntryCount: 3
        ))
        for index in 0..<3 {
            #expect(KeymapProtocol.encodeKeymapEntry(
                keycode: keycode,
                semantic: semantic,
                style: style,
                at: UInt8(index),
                to: bytes
            ))
        }
    }

    var session = KeymapTransferSession()
    #expect(session.start() == [.write(KeymapProtocol.makeKeymapMetadataRequest())])
    #expect(session.receive(metadata) == [.write(KeymapProtocol.makeKeymapChunkRequest(startingAt: 0))])

    let completion = session.receive(chunk)
    #expect(completion.count == 2)
    guard case let .keymap(keymap) = completion.first else {
        Issue.record("The completed transfer did not publish its keymap.")
        return
    }
    #expect(keymap.hasValidFingerprint)
    #expect(keymap.entries == Array(
        repeating: FirmwareKeymapEntry(keycode: keycode, semantic: semantic, style: .standard),
        count: 3
    ))
    #expect(completion.last == .write(KeymapProtocol.makeStateRequest()))
}
