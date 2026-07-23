import Dispatch
import Foundation
import KeymapCompanionCore

/// A blocking Windows HID read session with an independent serialized write path.
///
/// ``stateLock`` protects transfer and lifecycle state. ``readQueue`` owns input processing,
/// while ``writeQueue`` ensures output reports never wait behind a blocking read.
final class WindowsHIDSession: @unchecked Sendable {
    /// The Windows device path.
    let path: String

    /// The receiver for validated session events.
    private let eventHandler: @Sendable (_ event: KeyboardMonitorEvent) -> Void

    /// The queue that owns the blocking input loop.
    private let readQueue: DispatchQueue

    /// The queue that serializes output reports independently of input.
    private let writeQueue: DispatchQueue

    /// The synchronous transport for this endpoint.
    private let transport: any WindowsHIDTransport

    /// The lock protecting lifecycle and transfer state.
    private let stateLock = NSLock()

    /// Whether cancellation has started.
    private var isClosingStorage = false

    /// Whether the blocking read loop has started.
    private var hasStartedReadLoop = false

    /// The platform-neutral transfer engine.
    private var transferSession = KeymapTransferSession()

    /// The most recently validated complete keymap.
    var latestKeymap: FirmwareKeymap? {
        stateLock.withLock { transferSession.latestKeymap }
    }

    /// The most recently validated keyboard state.
    var latestReport: KeyboardStateReport? {
        stateLock.withLock { transferSession.latestReport }
    }

    /// Creates a Windows HID session around an open synchronous transport.
    ///
    /// - Parameters:
    ///   - path: The Windows device path.
    ///   - transport: The open synchronous transport.
    ///   - eventHandler: The receiver for validated session events.
    init(
        path: String,
        transport: any WindowsHIDTransport,
        eventHandler: @escaping @Sendable (_ event: KeyboardMonitorEvent) -> Void
    ) {
        self.path = path
        self.transport = transport
        self.eventHandler = eventHandler
        let queueIdentifier = path.hashValue
        readQueue = DispatchQueue(label: "KeymapCompanion.HIDSession.Read.\(queueIdentifier)")
        writeQueue = DispatchQueue(label: "KeymapCompanion.HIDSession.Write.\(queueIdentifier)")
    }

    /// Starts the keymap handshake and blocking input loop once.
    func start() {
        let shouldStart = stateLock.withLock {
            guard !isClosingStorage, !hasStartedReadLoop else { return false }
            hasStartedReadLoop = true
            return true
        }
        guard shouldStart else { return }

        readQueue.async { [self] in
            let actions = stateLock.withLock { transferSession.start() }
            perform(actions)
            readReportsUntilClosed()
            writeQueue.sync {}
            transport.destroy()
        }
    }

    /// Enqueues an RGB Matrix write independently of the blocking input loop.
    ///
    /// - Parameter settings: The complete base-layer configuration to persist.
    func applyRGBSettings(_ settings: RGBSettings) {
        let request = stateLock.withLock { () -> [UInt8]? in
            guard !isClosingStorage else { return nil }
            return transferSession.rgbSettingsRequest(for: settings)
        }
        guard let request else { return }
        enqueueWrite(request)
    }

    /// Cancels input and prevents new output reports.
    func close() {
        let shouldDestroyWithoutReadLoop = stateLock.withLock { () -> Bool? in
            guard !isClosingStorage else { return nil }
            isClosingStorage = true
            return !hasStartedReadLoop
        }
        guard let shouldDestroyWithoutReadLoop else { return }

        transport.cancel()
        if shouldDestroyWithoutReadLoop {
            writeQueue.async { [transport] in
                transport.destroy()
            }
        }
    }

    /// Returns whether cancellation has started.
    private var isClosing: Bool {
        stateLock.withLock { isClosingStorage }
    }

    /// Reads and decodes reports until cancellation or transport failure.
    private func readReportsUntilClosed() {
        var report = [UInt8](repeating: 0, count: KeymapProtocol.reportSize)
        while !isClosing {
            let result = report.withUnsafeMutableBufferPointer { buffer in
                transport.readReport(into: buffer)
            }
            if result == Int32(KeymapProtocol.reportSize) {
                let actions = stateLock.withLock { transferSession.receive(report) }
                perform(actions)
            } else if !isClosing {
                eventHandler(.failed(message: "The keyboard stopped responding over Raw HID."))
                close()
            }
        }
    }

    /// Performs protocol actions in their declared order.
    ///
    /// - Parameter actions: The protocol actions to perform.
    private func perform(_ actions: [KeymapSessionAction]) {
        for action in actions {
            switch action {
            case let .write(bytes):
                enqueueWrite(bytes)
            case let .keymap(keymap):
                eventHandler(.keymap(keymap))
            case let .state(report):
                eventHandler(.state(report))
            case let .layerHUDTrigger(trigger):
                eventHandler(.layerHUDTrigger(trigger))
            case let .crashReport(report):
                do {
                    try CrashReportLog.persist(report)
                    enqueueWrite(KeymapProtocol.makeClearCrashReportRequest())
                } catch {
                    eventHandler(.failed(
                        message: "Could not persist firmware crash report: \(error.localizedDescription)"
                    ))
                }
            case let .failed(message):
                eventHandler(.failed(message: message))
            }
        }
    }

    /// Enqueues one complete output report on the serialized write path.
    ///
    /// - Parameter bytes: The complete protocol report to write.
    private func enqueueWrite(_ bytes: [UInt8]) {
        writeQueue.async { [self] in
            guard !isClosing else { return }
            let result = bytes.withUnsafeBufferPointer { buffer in
                transport.writeReport(buffer)
            }
            if result != Int32(bytes.count), !isClosing {
                eventHandler(.failed(message: "Could not write to the keyboard's Raw HID endpoint."))
            }
        }
    }
}
