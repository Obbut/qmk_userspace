import CWindowsHID
import Dispatch
import Foundation
import KeymapCompanionCore

/// Main-actor adapter that satisfies the shared hardware dependency while the
/// underlying Windows HID monitor keeps blocking reads on private queues.
@MainActor
final class WindowsKeyboardHardwareClient: KeyboardHardwareClient {
    private var eventHandler: @MainActor @Sendable (KeyboardMonitorEvent) -> Void = { _ in }
    private lazy var monitor = WindowsHIDMonitor { [weak self] event in
        DispatchQueue.main.async { [weak self] in
            self?.eventHandler(event)
        }
    }

    func setEventHandler(
        _ handler: @escaping @MainActor @Sendable (KeyboardMonitorEvent) -> Void
    ) {
        eventHandler = handler
    }

    func start() { monitor.start() }
    func restart() { monitor.restart() }
    func applyRGBSettings(_ settings: RGBSettings) { monitor.applyRGBSettings(settings) }
    func stop() { monitor.stop() }
}

/// Discovers QMK Raw HID endpoints with Windows SetupAPI and feeds their packets
/// through the platform-neutral keymap transfer engine.
final class WindowsHIDMonitor: @unchecked Sendable {
    typealias EventHandler = @Sendable (KeyboardMonitorEvent) -> Void

    private let eventHandler: EventHandler
    private let queue = DispatchQueue(label: "KeymapCompanion.WindowsHIDMonitor")
    private var timer: DispatchSourceTimer?
    private var sessions: [String: WindowsHIDSession] = [:]
    private var activePath: String?

    init(eventHandler: @escaping EventHandler) {
        self.eventHandler = eventHandler
    }

    func start() {
        queue.async { [self] in
            guard timer == nil else { return }
            eventHandler(.searching)

            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(150))
            timer.setEventHandler { [weak self] in self?.scan() }
            self.timer = timer
            timer.resume()
        }
    }

    func restart() {
        queue.async { [self] in
            sessions.values.forEach { $0.close() }
            sessions.removeAll()
            activePath = nil
            eventHandler(.searching)
            scan()
        }
    }

    func stop() {
        queue.async { [self] in
            timer?.cancel()
            timer = nil
            sessions.values.forEach { $0.close() }
            sessions.removeAll()
            activePath = nil
        }
    }

    func applyRGBSettings(_ settings: RGBSettings) {
        queue.async { [self] in
            guard let activePath, let session = sessions[activePath] else { return }
            session.applyRGBSettings(settings)
        }
    }

    private func scan() {
        let descriptors = WindowsHIDDescriptor.enumerate()
        let paths = Set(descriptors.map(\.path))

        for path in Array(sessions.keys) where !paths.contains(path) {
            guard let removed = sessions.removeValue(forKey: path) else { continue }
            removed.close()
            if activePath == path {
                activePath = nil
                selectReplacementOrDisconnect()
            }
        }

        for descriptor in descriptors where sessions[descriptor.path] == nil {
            guard let session = WindowsHIDSession(
                descriptor: descriptor,
                eventHandler: { [weak self, path = descriptor.path] event in
                    guard let monitor = self else { return }
                    monitor.queue.async { monitor.receive(event, from: path) }
                }
            ) else { continue }
            sessions[descriptor.path] = session
            session.start()
        }
    }

    private func receive(_ event: KeyboardMonitorEvent, from path: String) {
        guard sessions[path] != nil else { return }
        switch event {
        case .keymap, .state:
            activePath = path
        case .failed:
            break
        case .searching, .disconnected:
            return
        }
        eventHandler(event)
    }

    private func selectReplacementOrDisconnect() {
        if let replacement = sessions.values.first(where: {
            $0.latestKeymap != nil && $0.latestReport != nil
        }), let keymap = replacement.latestKeymap, let report = replacement.latestReport {
            activePath = replacement.path
            eventHandler(.keymap(keymap))
            eventHandler(.state(report))
        } else {
            eventHandler(.disconnected)
        }
    }
}

private struct WindowsHIDDescriptor: Sendable {
    let path: String
    let inputReportLength: UInt16
    let outputReportLength: UInt16

    static func enumerate() -> [Self] {
        final class ResultBox {
            var descriptors: [WindowsHIDDescriptor] = []
        }

        let box = ResultBox()
        let context = Unmanaged.passUnretained(box).toOpaque()
        keymap_hid_enumerate(
            UInt16(KeymapProtocol.usagePage),
            UInt16(KeymapProtocol.usage),
            { path, inputLength, outputLength, context in
                guard let path, let context else { return }
                let box = Unmanaged<ResultBox>.fromOpaque(context).takeUnretainedValue()
                box.descriptors.append(
                    WindowsHIDDescriptor(
                        path: String(decodingCString: path, as: UTF16.self),
                        inputReportLength: inputLength,
                        outputReportLength: outputLength
                    )
                )
            },
            context
        )
        return box.descriptors
    }
}

/// Owns one blocking Windows HID read loop. All transfer-engine mutations happen
/// on `queue`; cancellation is safe from the monitor queue.
private final class WindowsHIDSession: @unchecked Sendable {
    let path: String

    private let eventHandler: @Sendable (KeyboardMonitorEvent) -> Void
    private let queue: DispatchQueue
    private let handle: OpaquePointer
    private let stateLock = NSLock()
    private var isClosed = false
    private var transferSession = KeymapTransferSession()

    var latestKeymap: FirmwareKeymap? {
        stateLock.withLock { transferSession.latestKeymap }
    }

    var latestReport: KeyboardStateReport? {
        stateLock.withLock { transferSession.latestReport }
    }

    init?(
        descriptor: WindowsHIDDescriptor,
        eventHandler: @escaping @Sendable (KeyboardMonitorEvent) -> Void
    ) {
        let pathUnits = Array(descriptor.path.utf16) + [0]
        let opened = pathUnits.withUnsafeBufferPointer { pathBuffer in
            keymap_hid_open(
                pathBuffer.baseAddress,
                descriptor.inputReportLength,
                descriptor.outputReportLength
            )
        }
        guard let opened else { return nil }

        path = descriptor.path
        self.eventHandler = eventHandler
        queue = DispatchQueue(label: "KeymapCompanion.HIDSession.\(descriptor.path.hashValue)")
        handle = opened
    }

    func start() {
        queue.async { [self] in
            stateLock.lock()
            let actions = transferSession.start()
            stateLock.unlock()
            handleActions(actions)
            readLoop()
            keymap_hid_destroy(handle)
        }
    }

    func applyRGBSettings(_ settings: RGBSettings) {
        queue.async { [self] in
            guard !closed else { return }
            send(transferSession.rgbSettingsRequest(settings))
        }
    }

    func close() {
        let shouldCancel = stateLock.withLock {
            guard !isClosed else { return false }
            isClosed = true
            return true
        }
        if shouldCancel { keymap_hid_cancel(handle) }
    }

    private var closed: Bool {
        stateLock.withLock { isClosed }
    }

    private func readLoop() {
        var report = [UInt8](repeating: 0, count: KeymapProtocol.reportSize)
        while !closed {
            let result = report.withUnsafeMutableBufferPointer { buffer in
                keymap_hid_read_report(handle, buffer.baseAddress, UInt32(buffer.count))
            }
            if result == Int32(KeymapProtocol.reportSize) {
                stateLock.lock()
                let actions = transferSession.receive(report)
                stateLock.unlock()
                handleActions(actions)
            } else if !closed {
                eventHandler(.failed("The keyboard stopped responding over Raw HID."))
                close()
            }
        }
    }

    private func handleActions(_ actions: [KeymapSessionAction]) {
        for action in actions {
            switch action {
            case let .write(bytes):
                send(bytes)
            case let .keymap(keymap):
                eventHandler(.keymap(keymap))
            case let .state(report):
                eventHandler(.state(report))
            case let .failed(message):
                eventHandler(.failed(message))
            }
        }
    }

    private func send(_ bytes: [UInt8]) {
        guard !closed else { return }
        let result = bytes.withUnsafeBufferPointer { buffer in
            keymap_hid_write_report(handle, buffer.baseAddress, UInt32(buffer.count))
        }
        if result != Int32(bytes.count), !closed {
            eventHandler(.failed("Could not write to the keyboard's Raw HID endpoint."))
        }
    }
}
