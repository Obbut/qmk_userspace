import Testing
@testable import KeymapCompanion

/// Verifies that the host request exactly matches the firmware protocol header.
@Test
func stateRequestUsesFixedRawHIDEnvelope() {
    let request = KeymapProtocol.makeStateRequest()

    #expect(request.count == 32)
    #expect(Array(request[0..<4]) == Array("KMAP".utf8))
    #expect(request[4] == 1)
    #expect(request[5] == 1)
    #expect(request.dropFirst(6).allSatisfy { $0 == 0 })
}

/// Verifies little-endian packet fields and keyboard identity.
@Test
func parsesKeyboardStateReport() {
    var packet = [UInt8](repeating: 0, count: 32)
    packet.replaceSubrange(0..<4, with: Array("KMAP".utf8))
    packet[4] = 1
    packet[5] = 2
    packet[6] = KeyboardKind.elora.rawValue
    packet.replaceSubrange(8..<12, with: [0b0000_0110, 0, 0, 0])
    packet.replaceSubrange(12..<16, with: [1, 0, 0, 0])
    packet.replaceSubrange(16..<20, with: [42, 0, 0, 0])
    packet.replaceSubrange(20..<24, with: [1, 0, 0, 0])

    let report = KeymapProtocol.parseStateReport(packet)

    #expect(report?.keyboardKind == .elora)
    #expect(report?.layerStateMask == 6)
    #expect(report?.defaultLayerStateMask == 1)
    #expect(report?.effectiveLayerMask == 7)
    #expect(report?.sequence == 42)
    #expect(report?.capabilities == 1)
}

/// Verifies unrelated Raw HID traffic is ignored safely.
@Test
func rejectsUnknownRawHIDPacket() {
    let unknownPacket = [UInt8](repeating: 0xFF, count: 32)

    #expect(KeymapProtocol.parseStateReport(unknownPacket) == nil)
}
