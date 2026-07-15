import AppKit
import Testing
@testable import KeymapCompanion

/// Verifies requests use the sole protocol-v4 Raw HID envelope.
@Test
func metadataRequestUsesProtocolFourEnvelope() {
    let request = KeymapProtocol.makeKeymapMetadataRequest()

    #expect(request.count == 32)
    #expect(Array(request[0..<4]) == Array("KMAP".utf8))
    #expect(request[4] == 4)
    #expect(request[5] == 3)
    #expect(request.dropFirst(6).allSatisfy { $0 == 0 })
}

/// Verifies any protocol version other than v4 is rejected.
@Test
func rejectsEveryNonV4ProtocolEnvelope() {
    var packet = [UInt8](repeating: 0, count: 32)
    packet.replaceSubrange(0..<4, with: Array("KMAP".utf8))
    packet[4] = 3
    packet[5] = 2

    #expect(KeymapProtocol.stateReport(from: packet) == nil)
    #expect(KeymapProtocol.keymapMetadataReport(from: packet) == nil)
    #expect(KeymapProtocol.keymapChunkReport(from: packet) == nil)
}

/// Verifies chunk requests encode their entry offset little-endian.
@Test
func keymapChunkRequestIncludesStartIndex() {
    let request = KeymapProtocol.makeKeymapChunkRequest(startingAt: 0x1234)

    #expect(request[5] == 5)
    #expect(request[6] == 0x34)
    #expect(request[7] == 0x12)
}

/// Verifies state reports round-trip opaque layout IDs and RGB settings.
@Test
func stateReportRoundTripsProtocolFour() throws {
    var packet = [UInt8](repeating: 0, count: KeymapProtocol.reportSize)
    let encoded = packet.withUnsafeMutableBufferPointer {
        KeymapProtocol.encodeStateReport(
            to: $0,
            layoutID: LayoutID.elora.rawValue,
            layerStateMask: 6,
            defaultLayerStateMask: 1,
            sequence: 42,
            includesRGBSettings: true,
            rgbEffect: RGBEffect.pixelFlow.rawValue,
            rgbHue: 47,
            rgbSaturation: 219,
            rgbBrightness: 96,
            isRGBEnabled: true,
            rgbSpeed: 137
        )
    }
    let report = try #require(KeymapProtocol.stateReport(from: packet))

    #expect(encoded)
    #expect(report.layoutID == .elora)
    #expect(report.layerStateMask == 6)
    #expect(report.defaultLayerStateMask == 1)
    #expect(report.effectiveLayerMask == 7)
    #expect(report.sequence == 42)
    #expect(report.rgbSettings?.effect == .pixelFlow)
    #expect(report.rgbSettings?.speed == 137)
}

/// Verifies metadata carries arbitrary layout, layer, encoder, and fingerprint data.
@Test
func metadataReportRoundTripsProtocolFour() throws {
    var packet = [UInt8](repeating: 0, count: KeymapProtocol.reportSize)
    let encoded = packet.withUnsafeMutableBufferPointer {
        KeymapProtocol.encodeKeymapMetadataReport(
            to: $0,
            layoutID: LayoutID.q15.rawValue,
            layerCount: 2,
            matrixRowCount: 2,
            matrixColumnCount: 3,
            fingerprint: 0xCAFE_BABE,
            semanticFingerprint: 0x1234_5678,
            styleFingerprint: 0x8765_4321,
            entryCount: 16,
            encoderCount: 1
        )
    }
    let metadata = try #require(KeymapProtocol.keymapMetadataReport(from: packet))

    #expect(encoded)
    #expect(metadata.layoutID == .q15)
    #expect(metadata.layerCount == 2)
    #expect(metadata.matrixRowCount == 2)
    #expect(metadata.matrixColumnCount == 3)
    #expect(metadata.entryCount == 16)
    #expect(metadata.encoderCount == 1)
    #expect(metadata.fingerprint == 0xCAFE_BABE)
    #expect(metadata.semanticFingerprint == 0x1234_5678)
    #expect(metadata.styleFingerprint == 0x8765_4321)
}

/// Verifies protocol v4 does not impose a fixed keyboard encoder shape.
@Test
func metadataAcceptsArbitraryEncoderCount() throws {
    let encoderCount = UInt8(12)
    let entryCount = UInt16(1 + Int(encoderCount) * 2)
    var packet = [UInt8](repeating: 0, count: KeymapProtocol.reportSize)
    let encoded = packet.withUnsafeMutableBufferPointer {
        KeymapProtocol.encodeKeymapMetadataReport(
            to: $0,
            layoutID: 0x1020_3040,
            layerCount: 1,
            matrixRowCount: 1,
            matrixColumnCount: 1,
            fingerprint: 1,
            semanticFingerprint: 2,
            styleFingerprint: 3,
            entryCount: entryCount,
            encoderCount: encoderCount
        )
    }
    let report = try #require(KeymapProtocol.keymapMetadataReport(from: packet))

    #expect(encoded)
    #expect(report.encoderCount == 12)
    #expect(report.entryCount == Int(entryCount))
}

/// Verifies chunks carry 16-bit opaque semantic and style identifiers.
@Test
func keymapChunkRoundTripsGeneratedMetadataIdentifiers() throws {
    var packet = [UInt8](repeating: 0, count: KeymapProtocol.reportSize)
    packet.withUnsafeMutableBufferPointer { bytes in
        #expect(
            KeymapProtocol.encodeKeymapChunkHeader(
                to: bytes,
                layoutID: LayoutID.kyria.rawValue,
                entryCount: 2,
                startIndex: 5,
                totalEntryCount: 7
            )
        )
        #expect(
            KeymapProtocol.encodeKeymapEntry(
                keycode: 0x5220,
                semanticID: 0x1234,
                styleID: 0x5678,
                at: 0,
                to: bytes
            )
        )
        #expect(
            KeymapProtocol.encodeKeymapEntry(
                keycode: 0x7E02,
                semanticID: 0x9ABC,
                styleID: 0xDEF0,
                at: 1,
                to: bytes
            )
        )
    }
    let chunk = try #require(KeymapProtocol.keymapChunkReport(from: packet))

    #expect(chunk.layoutID == .kyria)
    #expect(chunk.startIndex == 5)
    #expect(chunk.totalEntryCount == 7)
    #expect(
        chunk.entries == [
            FirmwareKeymapEntry(
                keycode: 0x5220,
                semanticID: .init(rawValue: 0x1234),
                styleID: .init(rawValue: 0x5678)
            ),
            FirmwareKeymapEntry(
                keycode: 0x7E02,
                semanticID: .init(rawValue: 0x9ABC),
                styleID: .init(rawValue: 0xDEF0)
            ),
        ]
    )
}

/// Verifies explicit RGB settings use the fixed host-to-keyboard payload.
@Test
func rgbSettingsRequestUsesExplicitValues() {
    let settings = RGBSettings(
        isEnabled: true,
        effect: .hueWave,
        hue: 91,
        saturation: 203,
        brightness: 107,
        speed: 149
    )
    let request = KeymapProtocol.makeRGBSettingsRequest(applying: settings)

    #expect(request[4] == 4)
    #expect(request[5] == 7)
    #expect(Array(request[6...11]) == [1, RGBEffect.hueWave.rawValue, 91, 203, 107, 149])
}

/// Keeps the app's stable effect identifiers aligned with the firmware table.
@Test
func rgbEffectIdentifiersAreContiguous() {
    #expect(RGBEffect.allCases.count == 30)
    #expect(RGBEffect.allCases.map(\.rawValue) == Array(UInt8(1)...UInt8(30)))
}

/// Verifies the native color picker maps back to QMK HSV components.
@Test
func nativeColorSelectionUpdatesQMKComponents() {
    var settings = RGBSettings.default
    settings.color = NSColor(
        hue: 0.5,
        saturation: 0.25,
        brightness: 0.75,
        alpha: 1
    ).cgColor

    #expect(settings.hue == 128)
    #expect(settings.saturation == 64)
    #expect(settings.brightness == 96)
}

/// Verifies unrelated Raw HID traffic is ignored safely.
@Test
func rejectsUnknownRawHIDPacket() {
    let unknownPacket = [UInt8](repeating: 0xFF, count: 32)

    #expect(KeymapProtocol.stateReport(from: unknownPacket) == nil)
    #expect(KeymapProtocol.keymapMetadataReport(from: unknownPacket) == nil)
    #expect(KeymapProtocol.keymapChunkReport(from: unknownPacket) == nil)
}
