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
    #expect(transport.waitForWrite(timeout: .now() + .seconds(1)))

    session.applyRGBSettings(.default)
    #expect(transport.waitForWrite(timeout: .now() + .seconds(1)))
    #expect(transport.capturedReports.count == 2)
    #expect(transport.capturedReports.last?[5] == 7)

    session.close()
}
