import AppKit
import Testing
@testable import KeymapCompanion

/// Verifies that the metadata handshake exactly matches protocol v3.
@Test
func metadataRequestUsesFixedRawHIDEnvelope() {
    let request = KeymapProtocol.makeKeymapMetadataRequest()

    #expect(request.count == 32)
    #expect(Array(request[0..<4]) == Array("KMAP".utf8))
    #expect(request[4] == 3)
    #expect(request[5] == 3)
    #expect(request.dropFirst(6).allSatisfy { $0 == 0 })
}

/// Verifies that chunk requests encode their entry offset little-endian.
@Test
func keymapChunkRequestIncludesStartIndex() {
    let request = KeymapProtocol.makeKeymapChunkRequest(startingAt: 0x1234)

    #expect(request[5] == 5)
    #expect(request[6] == 0x34)
    #expect(request[7] == 0x12)
}

/// Verifies little-endian state fields and keyboard identity.
@Test
func parsesKeyboardStateReport() {
    var packet = makePacket(type: 2)
    packet[6] = KeyboardKind.elora.rawValue
    packet.replaceSubrange(8..<12, with: [0b0000_0110, 0, 0, 0])
    packet.replaceSubrange(12..<16, with: [1, 0, 0, 0])
    packet.replaceSubrange(16..<20, with: [42, 0, 0, 0])
    packet.replaceSubrange(20..<24, with: [3, 0, 0, 0])

    let report = KeymapProtocol.parseStateReport(packet)

    #expect(report?.keyboardKind == .elora)
    #expect(report?.layerStateMask == 6)
    #expect(report?.defaultLayerStateMask == 1)
    #expect(report?.effectiveLayerMask == 7)
    #expect(report?.sequence == 42)
    #expect(report?.capabilities == 3)
    #expect(report?.rgbSettings == nil)
}

/// Verifies keymap metadata dimensions and the transfer fingerprint.
@Test
func parsesKeymapMetadataReport() {
    var packet = makePacket(type: 4)
    packet[6] = KeyboardKind.kyria.rawValue
    packet[7] = 5
    packet[8] = 10
    packet[9] = 7
    packet[10] = 4
    packet[11] = 5
    packet.replaceSubrange(12..<16, with: [0x78, 0x56, 0x34, 0x12])
    packet.replaceSubrange(16..<18, with: [0x68, 0x01])
    packet[18] = 1
    packet[19] = 2

    let metadata = KeymapProtocol.parseKeymapMetadataReport(packet)

    #expect(metadata?.keyboardKind == .kyria)
    #expect(metadata?.layerCount == 5)
    #expect(metadata?.matrixRowCount == 10)
    #expect(metadata?.matrixColumnCount == 7)
    #expect(metadata?.entriesPerChunk == 5)
    #expect(metadata?.entryCount == 360)
    #expect(metadata?.encoderCount == 1)
    #expect(metadata?.fingerprint == 0x1234_5678)
}

/// Proves that the firmware-side shared encoder produces metadata the host-side decoder accepts.
@Test
func sharedMetadataEncoderRoundTripsProtocolV3() {
    var packet = [UInt8](repeating: 0xFF, count: KeymapProtocol.reportSize)
    let encoded = packet.withUnsafeMutableBufferPointer {
        KeymapProtocol.encodeKeymapMetadataReport(
            to: $0,
            keyboardKind: KeyboardKind.elora.rawValue,
            layerCount: 1,
            matrixRowCount: 1,
            matrixColumnCount: 1,
            fingerprint: 0xCAFE_BABE,
            entryCount: 3,
            encoderCount: 1
        )
    }

    let metadata = KeymapProtocol.parseKeymapMetadataReport(packet)

    #expect(encoded)
    #expect(metadata?.keyboardKind == .elora)
    #expect(metadata?.entryCount == 3)
    #expect(metadata?.encoderCount == 1)
    #expect(packet[19] == UInt8(EncoderDirection.allCases.count))
    #expect(metadata?.fingerprint == 0xCAFE_BABE)
}

/// Verifies keycodes, firmware semantics, and styles within a transfer page.
@Test
func parsesKeymapChunkReport() {
    var packet = makePacket(type: 6)
    packet[6] = KeyboardKind.kyria.rawValue
    packet[7] = 2
    packet.replaceSubrange(8..<10, with: [5, 0])
    packet.replaceSubrange(10..<12, with: [0x68, 0x01])
    packet.replaceSubrange(12..<16, with: [0x1E, 0x02, 0, KeyStyle.yellow.rawValue])
    packet.replaceSubrange(16..<20, with: [0x20, 0x52, 1, KeyStyle.purple.rawValue])

    let chunk = KeymapProtocol.parseKeymapChunkReport(packet)

    #expect(chunk?.startIndex == 5)
    #expect(chunk?.totalEntryCount == 360)
    #expect(chunk?.entries == [
        FirmwareKeymapEntry(keycode: 0x021E, semantic: 0, style: .yellow),
        FirmwareKeymapEntry(keycode: 0x5220, semantic: 1, style: .purple)
    ])
}

/// Verifies the app uses the same byte-wise FNV-1a fingerprint as firmware.
@Test
func validatesFirmwareKeymapFingerprint() {
    let keymap = FirmwareKeymap(
        keyboardKind: .kyria,
        layerCount: 1,
        matrixRowCount: 1,
        matrixColumnCount: 1,
        encoderCount: 1,
        fingerprint: 0x8DF5_1499,
        entries: [
            FirmwareKeymapEntry(keycode: 0x1234, semantic: 2, style: .red),
            FirmwareKeymapEntry(keycode: 0x00AC, semantic: 0, style: .standard),
            FirmwareKeymapEntry(keycode: 0x00AB, semantic: 0, style: .standard)
        ]
    )

    #expect(keymap.hasValidFingerprint)
}

/// Verifies that explicit RGB settings use the fixed host-to-keyboard payload.
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

    let request = KeymapProtocol.makeRGBSettingsRequest(settings)

    #expect(request.count == 32)
    #expect(Array(request[0..<4]) == Array("KMAP".utf8))
    #expect(request[4] == 3)
    #expect(request[5] == 7)
    #expect(request[6] == 1)
    #expect(request[7] == RGBEffect.hueWave.rawValue)
    #expect(Array(request[8...11]) == [91, 203, 107, 149])
    #expect(request.dropFirst(12).allSatisfy { $0 == 0 })
}

/// Verifies that RGB capability state is decoded alongside layer state.
@Test
func parsesRGBSettingsFromStateReport() {
    var packet = makePacket(type: 2)
    packet[6] = KeyboardKind.kyria.rawValue
    packet[8] = 1
    packet[12] = 1
    packet[20] = 7
    packet[24] = RGBEffect.pixelFlow.rawValue
    packet[25] = 47
    packet[26] = 219
    packet[27] = 96
    packet[28] = 1
    packet[29] = 137
    packet[30] = UInt8(RGBEffect.allCases.count)

    let report = KeymapProtocol.parseStateReport(packet)

    #expect(
        report?.rgbSettings == RGBSettings(
            isEnabled: true,
            effect: .pixelFlow,
            hue: 47,
            saturation: 219,
            brightness: 96,
            speed: 137
        )
    )
}

/// Keeps the app's stable effect identifiers aligned with the firmware table.
@Test
func rgbEffectIdentifiersAreContiguous() {
    #expect(RGBEffect.allCases.count == 30)
    #expect(RGBEffect.allCases.map(\.rawValue) == Array(UInt8(1)...UInt8(30)))
}

/// Verifies that the native color picker maps back to QMK HSV components.
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

/// Verifies native brightness and speed sliders map to the full QMK byte ranges.
@Test
func normalizedRGBControlsUpdateQMKValues() {
    var settings = RGBSettings.default

    settings.normalizedBrightness = 0.5
    settings.normalizedSpeed = 0.75

    #expect(settings.brightness == 64)
    #expect(settings.speed == 191)
    #expect(settings.normalizedBrightness == 0.5)
    #expect(abs(settings.normalizedSpeed - 0.75) < 0.002)
}

/// Verifies unrelated Raw HID traffic is ignored safely.
@Test
func rejectsUnknownRawHIDPacket() {
    let unknownPacket = [UInt8](repeating: 0xFF, count: 32)

    #expect(KeymapProtocol.parseStateReport(unknownPacket) == nil)
    #expect(KeymapProtocol.parseKeymapMetadataReport(unknownPacket) == nil)
    #expect(KeymapProtocol.parseKeymapChunkReport(unknownPacket) == nil)
}

/// Creates one zero-filled protocol v3 packet with a selected message type.
/// - Parameter type: The numeric protocol message type.
/// - Returns: A complete Raw HID packet.
private func makePacket(type: UInt8) -> [UInt8] {
    var packet = [UInt8](repeating: 0, count: 32)
    packet.replaceSubrange(0..<4, with: Array("KMAP".utf8))
    packet[4] = 3
    packet[5] = type
    return packet
}
