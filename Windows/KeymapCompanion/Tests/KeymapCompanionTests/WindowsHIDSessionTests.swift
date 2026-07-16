import Dispatch
import KeymapCompanionCore
import Testing
@testable import KeymapCompanion

/// Verifies lighting writes complete while the HID input operation remains blocked.
@Test
func lightingWriteDoesNotWaitForBlockingRead() {
    let transport = BlockingReadHIDTransport()
    let session = WindowsHIDSession(
        path: "test-device",
        transport: transport,
        eventHandler: { _ in }
    )

    session.start()
    #expect(transport.waitForRead(until: .now() + .seconds(1)))
    #expect(transport.waitForWrite(until: .now() + .seconds(1)))
    #expect(transport.waitForWrite(until: .now() + .seconds(1)))

    session.applyRGBSettings(.default)
    #expect(transport.waitForWrite(until: .now() + .seconds(1)))
    #expect(transport.capturedReports.count == 3)
    #expect(transport.capturedReports.last?[5] == 7)

    session.close()
    #expect(transport.waitForDestruction(until: .now() + .seconds(1)))
}

/// Verifies an unstarted session still releases its owned native transport.
@Test
func closingUnstartedSessionDestroysTransport() {
    let transport = BlockingReadHIDTransport()
    let session = WindowsHIDSession(
        path: "unstarted-test-device",
        transport: transport,
        eventHandler: { _ in }
    )

    session.close()

    #expect(transport.waitForDestruction(until: .now() + .seconds(1)))
}
