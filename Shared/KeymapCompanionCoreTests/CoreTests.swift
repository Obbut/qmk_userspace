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
