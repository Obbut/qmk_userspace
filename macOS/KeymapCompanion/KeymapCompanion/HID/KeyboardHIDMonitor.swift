import CoreFoundation
import Foundation
@preconcurrency import IOKit.hid

/// Discovers QMK Raw HID endpoints and keeps their state callbacks on the main run loop.
@MainActor
final class KeyboardHIDMonitor {
    /// Receives validated device-monitor events on the main actor.
    var eventHandler: @MainActor (KeyboardMonitorEvent) -> Void = { _ in }

    /// The macOS HID manager retained for the application's lifetime.
    private let manager: IOHIDManager

    /// Open Raw HID sessions keyed by Core Foundation object identity.
    private var sessions: [ObjectIdentifier: HIDDeviceSession] = [:]

    /// The endpoint currently supplying the visible keyboard state.
    private var activeSessionID: ObjectIdentifier?

    /// Whether the manager is currently open and scheduled.
    private var isRunning = false

    /// Creates a monitor configured for QMK's default Raw HID usage pair.
    init() {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matching: [String: Any] = [
            kIOHIDDeviceUsagePageKey: KeymapProtocol.usagePage,
            kIOHIDDeviceUsageKey: KeymapProtocol.usage
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
    }

    /// Opens the manager and begins discovery on the main run loop.
    func start() {
        guard !isRunning else { return }

        eventHandler(.searching)
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, result, _, device in
            guard result == kIOReturnSuccess, let context else { return }
            MainActor.assumeIsolated {
                let monitor = Unmanaged<KeyboardHIDMonitor>.fromOpaque(context).takeUnretainedValue()
                monitor.add(device)
            }
        }, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, result, _, device in
            guard result == kIOReturnSuccess, let context else { return }
            MainActor.assumeIsolated {
                let monitor = Unmanaged<KeyboardHIDMonitor>.fromOpaque(context).takeUnretainedValue()
                monitor.remove(device)
            }
        }, context)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)

        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard result == kIOReturnSuccess else {
            IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
            eventHandler(.failed("IOHIDManagerOpen failed with code \(result)"))
            return
        }
        isRunning = true
    }

    /// Closes all endpoints, then starts a fresh discovery pass.
    func restart() {
        stop()
        start()
    }

    /// Unschedules the manager and releases every open device endpoint.
    private func stop() {
        guard isRunning else { return }

        sessions.values.forEach { $0.close() }
        sessions.removeAll()
        activeSessionID = nil
        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        isRunning = false
    }

    /// Opens a newly matched Raw HID endpoint and requests current state.
    /// - Parameter device: The matched IOHID device.
    private func add(_ device: IOHIDDevice) {
        let id = ObjectIdentifier(device)
        guard sessions[id] == nil else { return }

        let session = HIDDeviceSession(device: device, monitor: self)
        guard session.open() == kIOReturnSuccess else { return }
        sessions[id] = session
        session.requestCurrentState()
    }

    /// Removes a device endpoint and updates visible connection state when needed.
    /// - Parameter device: The removed IOHID device.
    private func remove(_ device: IOHIDDevice) {
        let id = ObjectIdentifier(device)
        guard let session = sessions.removeValue(forKey: id) else { return }
        session.close()

        guard activeSessionID == id else { return }
        activeSessionID = nil
        if let replacement = sessions.first(where: { $0.value.latestReport != nil }),
           let report = replacement.value.latestReport {
            activeSessionID = replacement.key
            eventHandler(.state(report))
        } else {
            eventHandler(.disconnected)
        }
    }

    /// Accepts a validated report from one open session.
    /// - Parameters:
    ///   - report: The parsed QMK state packet.
    ///   - session: The endpoint that delivered it.
    fileprivate func receive(_ report: KeyboardStateReport, from session: HIDDeviceSession) {
        let id = ObjectIdentifier(session.device)
        session.latestReport = report
        activeSessionID = id
        eventHandler(.state(report))
    }

}

/// One open QMK Raw HID endpoint and its stable input-report buffer.
@MainActor
private final class HIDDeviceSession {
    /// The underlying IOHID device.
    let device: IOHIDDevice

    /// The most recent compatible packet received on this endpoint.
    var latestReport: KeyboardStateReport?

    /// The monitor that owns this session.
    private weak var monitor: KeyboardHIDMonitor?

    /// Stable storage required by IOHID's input-report callback API.
    private let reportBuffer: UnsafeMutablePointer<UInt8>

    /// Whether the endpoint is currently open.
    private var isOpen = false

    /// Creates a device session and allocates its callback buffer.
    /// - Parameters:
    ///   - device: The IOHID endpoint to wrap.
    ///   - monitor: The owning monitor.
    init(device: IOHIDDevice, monitor: KeyboardHIDMonitor) {
        self.device = device
        self.monitor = monitor
        reportBuffer = .allocate(capacity: KeymapProtocol.reportSize)
        reportBuffer.initialize(repeating: 0, count: KeymapProtocol.reportSize)
    }

    /// Releases the stable report buffer after the owning monitor closes the session.
    isolated deinit {
        reportBuffer.deallocate()
    }

    /// Opens the endpoint and registers its input callback.
    /// - Returns: The IOKit open result.
    func open() -> IOReturn {
        let result = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        guard result == kIOReturnSuccess else { return result }

        IOHIDDeviceRegisterInputReportCallback(
            device,
            reportBuffer,
            KeymapProtocol.reportSize,
            { context, result, _, _, _, report, reportLength in
                guard result == kIOReturnSuccess,
                      reportLength >= 0,
                      reportLength <= 32,
                      let context else { return }
                let bytes = Array(UnsafeBufferPointer(start: report, count: reportLength))

                MainActor.assumeIsolated {
                    guard let state = KeymapProtocol.parseStateReport(bytes) else { return }
                    let session = Unmanaged<HIDDeviceSession>.fromOpaque(context).takeUnretainedValue()
                    session.monitor?.receive(state, from: session)
                }
            },
            Unmanaged.passUnretained(self).toOpaque()
        )
        isOpen = true
        return result
    }

    /// Sends the protocol handshake and current-state request.
    func requestCurrentState() {
        let request = KeymapProtocol.makeStateRequest()
        request.withUnsafeBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            _ = IOHIDDeviceSetReport(
                device,
                kIOHIDReportTypeOutput,
                0,
                baseAddress,
                buffer.count
            )
        }
    }

    /// Closes the endpoint before its callback buffer is released.
    func close() {
        guard isOpen else { return }
        IOHIDDeviceRegisterInputReportCallback(
            device,
            reportBuffer,
            KeymapProtocol.reportSize,
            nil,
            nil
        )
        IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
        isOpen = false
    }

}
