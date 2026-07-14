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

    /// Sends a complete RGB Matrix configuration to the active keyboard.
    /// - Parameter settings: The persistent configuration to apply.
    func applyRGBSettings(_ settings: RGBSettings) {
        guard let activeSessionID,
              let session = sessions[activeSessionID] else { return }
        session.applyRGBSettings(settings)
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

    /// Opens a newly matched Raw HID endpoint and starts its keymap transfer.
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
           let report = replacement.value.latestReport {
            activeSessionID = replacement.key
            eventHandler(.keymap(keymap))
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

    /// Accepts a complete keymap from one open session.
    /// - Parameters:
    ///   - keymap: The downloaded and fingerprint-validated keymap.
    ///   - session: The endpoint that delivered it.
    fileprivate func receive(_ keymap: FirmwareKeymap, from session: HIDDeviceSession) {
        activeSessionID = ObjectIdentifier(session.device)
        eventHandler(.keymap(keymap))
    }

    /// Surfaces a malformed or inconsistent firmware transfer.
    /// - Parameter message: The transfer validation failure.
    fileprivate func receiveTransferFailure(_ message: String) {
        eventHandler(.failed(message))
    }

}

/// One open QMK Raw HID endpoint and its stable input-report buffer.
@MainActor
private final class HIDDeviceSession {
    /// The underlying IOHID device.
    let device: IOHIDDevice

    /// The most recent compatible packet received on this endpoint.
    var latestReport: KeyboardStateReport?

    /// The complete keymap most recently downloaded from this endpoint.
    var latestKeymap: FirmwareKeymap?

    /// The monitor that owns this session.
    private weak var monitor: KeyboardHIDMonitor?

    /// Stable storage required by IOHID's input-report callback API.
    private let reportBuffer: UnsafeMutablePointer<UInt8>

    /// Whether the endpoint is currently open.
    private var isOpen = false

    /// Metadata for the keymap transfer currently in progress.
    private var keymapMetadata: KeymapMetadataReport?

    /// Consecutive entries accumulated for the current transfer.
    private var keymapEntries: [FirmwareKeymapEntry] = []

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
                      reportLength <= KeymapProtocol.reportSize,
                      let context else { return }
                let bytes = Array(UnsafeBufferPointer(start: report, count: reportLength))

                MainActor.assumeIsolated {
                    let session = Unmanaged<HIDDeviceSession>.fromOpaque(context).takeUnretainedValue()
                    session.receive(bytes)
                }
            },
            Unmanaged.passUnretained(self).toOpaque()
        )
        isOpen = true
        return result
    }

    /// Sends a complete RGB Matrix configuration to this keyboard.
    /// - Parameter settings: The persistent configuration to apply.
    func applyRGBSettings(_ settings: RGBSettings) {
        send(KeymapProtocol.makeRGBSettingsRequest(settings))
    }

    /// Starts the protocol handshake by requesting dimensions and a fingerprint.
    func requestKeymapMetadata() {
        send(KeymapProtocol.makeKeymapMetadataRequest())
    }

    /// Routes one input packet into the state or paginated keymap flow.
    /// - Parameter bytes: One complete Raw HID input report.
    private func receive(_ bytes: [UInt8]) {
        if let metadata = KeymapProtocol.parseKeymapMetadataReport(bytes) {
            beginKeymapTransfer(metadata)
            return
        }
        if let chunk = KeymapProtocol.parseKeymapChunkReport(bytes) {
            continueKeymapTransfer(chunk)
            return
        }
        if let state = KeymapProtocol.parseStateReport(bytes) {
            latestReport = state
            if latestKeymap?.keyboardKind == state.keyboardKind {
                monitor?.receive(state, from: self)
            }
        }
    }

    /// Resets transfer state and requests the first page.
    /// - Parameter metadata: The validated firmware transfer metadata.
    private func beginKeymapTransfer(_ metadata: KeymapMetadataReport) {
        keymapMetadata = metadata
        keymapEntries.removeAll(keepingCapacity: true)
        keymapEntries.reserveCapacity(metadata.entryCount)
        requestKeymapChunk(startingAt: 0)
    }

    /// Validates and appends one page, then requests the next page or publishes the result.
    /// - Parameter chunk: The decoded keymap page.
    private func continueKeymapTransfer(_ chunk: KeymapChunkReport) {
        guard let metadata = keymapMetadata,
              chunk.keyboardKind == metadata.keyboardKind,
              chunk.totalEntryCount == metadata.entryCount,
              chunk.startIndex == keymapEntries.count,
              chunk.entries.count <= metadata.entriesPerChunk else {
            monitor?.receiveTransferFailure("Firmware returned an inconsistent keymap chunk.")
            return
        }

        keymapEntries.append(contentsOf: chunk.entries)
        guard keymapEntries.count == metadata.entryCount else {
            requestKeymapChunk(startingAt: keymapEntries.count)
            return
        }

        let keymap = FirmwareKeymap(
            keyboardKind: metadata.keyboardKind,
            layerCount: metadata.layerCount,
            matrixRowCount: metadata.matrixRowCount,
            matrixColumnCount: metadata.matrixColumnCount,
            fingerprint: metadata.fingerprint,
            entries: keymapEntries
        )
        guard keymap.hasValidFingerprint else {
            monitor?.receiveTransferFailure("Firmware keymap fingerprint validation failed.")
            return
        }

        latestKeymap = keymap
        keymapMetadata = nil
        monitor?.receive(keymap, from: self)
        if let latestReport, latestReport.keyboardKind == keymap.keyboardKind {
            monitor?.receive(latestReport, from: self)
        } else {
            requestCurrentState()
        }
    }

    /// Requests the next transfer page.
    /// - Parameter startIndex: The first entry expected in the response.
    private func requestKeymapChunk(startingAt startIndex: Int) {
        guard let encodedIndex = UInt16(exactly: startIndex) else {
            monitor?.receiveTransferFailure("Firmware keymap is too large for protocol v2.")
            return
        }
        send(KeymapProtocol.makeKeymapChunkRequest(startingAt: encodedIndex))
    }

    /// Sends the current-state request after the keymap transfer completes.
    private func requestCurrentState() {
        send(KeymapProtocol.makeStateRequest())
    }

    /// Writes one fixed-size output report to the device.
    /// - Parameter request: A complete protocol request.
    private func send(_ request: [UInt8]) {
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
