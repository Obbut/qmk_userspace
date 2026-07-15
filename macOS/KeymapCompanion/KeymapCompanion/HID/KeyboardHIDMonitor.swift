import CoreFoundation
import Foundation
@preconcurrency import IOKit.hid
import KeymapCompanionCore

/// A main-actor monitor for QMK Raw HID endpoints and state callbacks.
@MainActor
final class KeyboardHIDMonitor: KeyboardHardwareClient {
    /// The main-actor callback that receives validated device-monitor events.
    private var eventHandler: @MainActor @Sendable (_ event: KeyboardMonitorEvent) -> Void = { _ in }

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
            kIOHIDDeviceUsageKey: KeymapProtocol.usage,
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
    }

    /// Installs the main-actor device-event receiver.
    ///
    /// - Parameter handler: The receiver for hardware lifecycle and state events.
    func setEventHandler(
        _ handler: @escaping @MainActor @Sendable (_ event: KeyboardMonitorEvent) -> Void
    ) {
        eventHandler = handler
    }

    /// Opens the manager and begins discovery on the main run loop.
    func start() {
        guard !isRunning else { return }

        eventHandler(.searching)
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(
            manager,
            { context, result, _, device in
                guard result == kIOReturnSuccess, let context else { return }
                MainActor.assumeIsolated {
                    let monitor = Unmanaged<KeyboardHIDMonitor>.fromOpaque(context).takeUnretainedValue()
                    monitor.add(device)
                }
            }, context)
        IOHIDManagerRegisterDeviceRemovalCallback(
            manager,
            { context, result, _, device in
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
            eventHandler(.failed(message: "IOHIDManagerOpen failed with code \(result)"))
            return
        }
        isRunning = true
    }

    /// Closes all endpoints, then starts a fresh discovery pass.
    func restart() {
        stop()
        start()
    }

    /// Sends a complete RGB Matrix configuration to the active keyboard.
    ///
    /// - Parameter settings: The persistent configuration to apply.
    func applyRGBSettings(_ settings: RGBSettings) {
        guard let activeSessionID,
            let session = sessions[activeSessionID]
        else { return }
        session.applyRGBSettings(settings)
    }

    /// Unschedules the manager and releases every open device endpoint.
    func stop() {
        guard isRunning else { return }

        sessions.values.forEach { $0.close() }
        sessions.removeAll()
        activeSessionID = nil
        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        isRunning = false
    }

    /// Opens a newly matched Raw HID endpoint and starts its keymap transfer.
    ///
    /// - Parameter device: The matched IOHID device.
    private func add(_ device: IOHIDDevice) {
        let id = ObjectIdentifier(device)
        guard sessions[id] == nil else { return }

        let session = HIDDeviceSession(device: device, monitor: self)
        guard session.open() == kIOReturnSuccess else { return }
        sessions[id] = session
        session.requestKeymapMetadata()
    }

    /// Removes a device endpoint and updates visible connection state when needed.
    ///
    /// - Parameter device: The removed IOHID device.
    private func remove(_ device: IOHIDDevice) {
        let id = ObjectIdentifier(device)
        guard let session = sessions.removeValue(forKey: id) else { return }
        session.close()

        guard activeSessionID == id else { return }
        activeSessionID = nil
        if let replacement = sessions.first(where: {
            $0.value.latestReport != nil && $0.value.latestKeymap != nil
        }),
            let keymap = replacement.value.latestKeymap,
            let report = replacement.value.latestReport
        {
            activeSessionID = replacement.key
            eventHandler(.keymap(keymap))
            eventHandler(.state(report))
        } else {
            eventHandler(.disconnected)
        }
    }

    /// Accepts a validated report from one open session.
    ///
    /// - Parameters:
    ///   - report: The parsed QMK state packet.
    ///   - session: The endpoint that delivered it.
    func receive(_ report: KeyboardStateReport, from session: HIDDeviceSession) {
        let id = ObjectIdentifier(session.device)
        activeSessionID = id
        eventHandler(.state(report))
    }

    /// Accepts a complete keymap from one open session.
    ///
    /// - Parameters:
    ///   - keymap: The downloaded and fingerprint-validated keymap.
    ///   - session: The endpoint that delivered it.
    func receive(_ keymap: FirmwareKeymap, from session: HIDDeviceSession) {
        activeSessionID = ObjectIdentifier(session.device)
        eventHandler(.keymap(keymap))
    }

    /// Surfaces a malformed or inconsistent firmware transfer.
    ///
    /// - Parameter message: The transfer validation failure.
    func receiveTransferFailure(_ message: String) {
        eventHandler(.failed(message: message))
    }
}
