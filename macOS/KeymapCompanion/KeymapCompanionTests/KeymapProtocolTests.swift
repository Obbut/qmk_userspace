import Testing
@testable import KeymapCompanion

/// Verifies that the metadata handshake exactly matches protocol v2.
@Test
func metadataRequestUsesFixedRawHIDEnvelope() {
    let request = KeymapProtocol.makeKeymapMetadataRequest()

    #expect(request.count == 32)
    #expect(Array(request[0..<4]) == Array("KMAP".utf8))
    #expect(request[4] == 2)
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
    packet.replaceSubrange(16..<18, with: [0x5E, 0x01])

    let metadata = KeymapProtocol.parseKeymapMetadataReport(packet)

    #expect(metadata?.keyboardKind == .kyria)
    #expect(metadata?.layerCount == 5)
    #expect(metadata?.matrixRowCount == 10)
    #expect(metadata?.matrixColumnCount == 7)
    #expect(metadata?.entriesPerChunk == 5)
    #expect(metadata?.entryCount == 350)
    #expect(metadata?.fingerprint == 0x1234_5678)
}

/// Verifies keycodes, firmware semantics, and styles within a transfer page.
@Test
func parsesKeymapChunkReport() {
    var packet = makePacket(type: 6)
    packet[6] = KeyboardKind.kyria.rawValue
    packet[7] = 2
    packet.replaceSubrange(8..<10, with: [5, 0])
    packet.replaceSubrange(10..<12, with: [0x5E, 0x01])
    packet.replaceSubrange(12..<16, with: [0x1E, 0x02, 0, KeyStyle.yellow.rawValue])
    packet.replaceSubrange(16..<20, with: [0x20, 0x52, 1, KeyStyle.purple.rawValue])

    let chunk = KeymapProtocol.parseKeymapChunkReport(packet)

    #expect(chunk?.startIndex == 5)
    #expect(chunk?.totalEntryCount == 350)
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
        fingerprint: 0x454E_649D,
        entries: [
            FirmwareKeymapEntry(keycode: 0x1234, semantic: 2, style: .red)
        ]
    )

    #expect(keymap.hasValidFingerprint)
}

/// Verifies unrelated Raw HID traffic is ignored safely.
@Test
func rejectsUnknownRawHIDPacket() {
    let unknownPacket = [UInt8](repeating: 0xFF, count: 32)

    #expect(KeymapProtocol.parseStateReport(unknownPacket) == nil)
    #expect(KeymapProtocol.parseKeymapMetadataReport(unknownPacket) == nil)
    #expect(KeymapProtocol.parseKeymapChunkReport(unknownPacket) == nil)
}

/// Creates one zero-filled protocol v2 packet with a selected message type.
/// - Parameter type: The numeric protocol message type.
/// - Returns: A complete Raw HID packet.
private func makePacket(type: UInt8) -> [UInt8] {
    var packet = [UInt8](repeating: 0, count: 32)
    packet.replaceSubrange(0..<4, with: Array("KMAP".utf8))
    packet[4] = 2
    packet[5] = type
    return packet
}
