import Dispatch
import Foundation
@testable import KeymapCompanion

/// A transport test double whose input remains blocked while output stays observable.
///
/// ``lock`` protects captured reports. Semaphores coordinate the read, write,
/// cancellation, and destruction operations without sharing mutable state.
final class BlockingReadHIDTransport: WindowsHIDTransport, @unchecked Sendable {
    /// The lock protecting captured reports.
    private let lock = NSLock()

    /// The signal that releases the simulated blocking read.
    private let readCancellation = DispatchSemaphore(value: 0)

    /// The signal emitted when the simulated read begins blocking.
    private let readStarted = DispatchSemaphore(value: 0)

    /// The signal emitted for every captured output report.
    private let writeCompleted = DispatchSemaphore(value: 0)

    /// The signal emitted when the transport is destroyed.
    private let destructionCompleted = DispatchSemaphore(value: 0)

    /// The captured output reports.
    private var reports: [[UInt8]] = []

    /// Blocks until cancellation and then reports a transport error.
    ///
    /// - Parameter buffer: Unused input storage.
    /// - Returns: A negative transport result after cancellation.
    func readReport(into buffer: UnsafeMutableBufferPointer<UInt8>) -> Int32 {
        readStarted.signal()
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
        destructionCompleted.signal()
    }

    /// Waits until the input operation has started blocking.
    ///
    /// - Parameter deadline: The absolute deadline for the wait.
    /// - Returns: `true` when the read starts before the deadline.
    func waitForRead(until deadline: DispatchTime) -> Bool {
        readStarted.wait(timeout: deadline) == .success
    }

    /// Waits for the next output report.
    ///
    /// - Parameter deadline: The absolute deadline for the wait.
    /// - Returns: `true` when a report arrives before the deadline.
    func waitForWrite(until deadline: DispatchTime) -> Bool {
        writeCompleted.wait(timeout: deadline) == .success
    }

    /// Waits until the session destroys the transport.
    ///
    /// - Parameter deadline: The absolute deadline for the wait.
    /// - Returns: `true` when destruction finishes before the deadline.
    func waitForDestruction(until deadline: DispatchTime) -> Bool {
        destructionCompleted.wait(timeout: deadline) == .success
    }

    /// The reports captured so far.
    var capturedReports: [[UInt8]] {
        lock.withLock { reports }
    }
}
