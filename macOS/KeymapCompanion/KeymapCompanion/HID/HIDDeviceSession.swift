import Foundation
@preconcurrency import IOKit.hid
import KeymapCompanionCore

/// One open QMK Raw HID endpoint and its stable input-report buffer.
@MainActor
final class HIDDeviceSession {
    /// The underlying IOHID device.
    let device: IOHIDDevice

    /// Platform-neutral packet decoding and keymap pagination state.
    private var transferSession = KeymapTransferSession()

    /// The most recent compatible packet received on this endpoint.
    var latestReport: KeyboardStateReport? { transferSession.latestReport }

    /// The complete keymap most recently downloaded from this endpoint.
    var latestKeymap: FirmwareKeymap? { transferSession.latestKeymap }

    /// The monitor that owns this session.
    private weak var monitor: KeyboardHIDMonitor?

    /// Stable storage required by IOHID's input-report callback API.
    private let reportBuffer: UnsafeMutablePointer<UInt8>

    /// Whether the endpoint is currently open.
    private var isOpen = false

    /// Creates a device session and allocates its callback buffer.
    ///
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
    ///
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
                    let context
                else { return }
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
    ///
    /// - Parameter settings: The persistent configuration to apply.
    func applyRGBSettings(_ settings: RGBSettings) {
        send(transferSession.rgbSettingsRequest(for: settings))
    }

    /// Starts the protocol handshake by requesting dimensions and a fingerprint.
    func requestKeymapMetadata() {
        perform(transferSession.start())
    }

    /// Routes one input packet into the state or paginated keymap flow.
    ///
    /// - Parameter bytes: One complete Raw HID input report.
    private func receive(_ bytes: [UInt8]) {
        perform(transferSession.receive(bytes))
    }

    /// Performs protocol actions on this HID endpoint and its owning monitor.
    ///
    /// - Parameter actions: The protocol actions to perform in order.
    private func perform(_ actions: [KeymapSessionAction]) {
        for action in actions {
            switch action {
            case let .write(request):
                send(request)
            case let .keymap(keymap):
                monitor?.receive(keymap, from: self)
            case let .state(report):
                monitor?.receive(report, from: self)
            case let .crashReport(report):
                do {
                    try CrashReportLog.persist(report)
                    send(KeymapProtocol.makeClearCrashReportRequest())
                } catch {
                    monitor?.receiveTransferFailure(
                        "Could not persist firmware crash report: \(error.localizedDescription)"
                    )
                }
            case let .failed(message):
                monitor?.receiveTransferFailure(message)
            }
        }
    }

    /// Writes one fixed-size output report to the device.
    ///
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
