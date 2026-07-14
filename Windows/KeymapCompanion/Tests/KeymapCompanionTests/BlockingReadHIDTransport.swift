import Dispatch
import Foundation
@testable import KeymapCompanion

/// A transport test double whose input remains blocked while output stays observable.
final class BlockingReadHIDTransport: WindowsHIDTransport, @unchecked Sendable {
    /// The lock protecting captured reports and lifecycle state.
    private let lock = NSLock()

    /// The signal that releases the simulated blocking read.
    private let readCancellation = DispatchSemaphore(value: 0)

    /// The signal emitted for every captured output report.
    private let writeCompleted = DispatchSemaphore(value: 0)

    /// The captured output reports.
    private var reports: [[UInt8]] = []

    /// Whether the transport has been destroyed.
    private var isDestroyed = false

    /// Blocks until cancellation and then reports a transport error.
    ///
    /// - Parameter buffer: Unused input storage.
    /// - Returns: A negative transport result after cancellation.
    func readReport(into buffer: UnsafeMutableBufferPointer<UInt8>) -> Int32 {
        readCancellation.wait()
        return -1
    }

    /// Captures an output report without releasing the blocked input operation.
    ///
    /// - Parameter bytes: The complete output report.
    /// - Returns: The number of captured bytes.
    func writeReport(_ bytes: UnsafeBufferPointer<UInt8>) -> Int32 {
        lock.withLock {
            reports.append(Array(bytes))
        }
        writeCompleted.signal()
        return Int32(bytes.count)
    }

    /// Releases the blocked input operation.
    func cancel() {
        readCancellation.signal()
    }

    /// Records native-resource destruction.
    func destroy() {
        lock.withLock {
            isDestroyed = true
        }
    }

    /// Waits for the next output report.
    ///
    /// - Parameter timeout: The maximum wait duration.
    /// - Returns: `true` when a report arrives before the timeout.
    func waitForWrite(timeout: DispatchTime) -> Bool {
        writeCompleted.wait(timeout: timeout) == .success
    }

    /// The reports captured so far.
    var capturedReports: [[UInt8]] {
        lock.withLock { reports }
    }

    /// Whether session cleanup destroyed the transport.
    var wasDestroyed: Bool {
        lock.withLock { isDestroyed }
    }
}
