import Dispatch
import KeymapCompanionCore

/// The main-actor adapter for the Windows keyboard hardware implementation.
@MainActor
final class WindowsKeyboardHardwareClient: KeyboardHardwareClient {
    /// The receiver installed by the shared model.
    private var eventHandler: @MainActor @Sendable (_ event: KeyboardMonitorEvent) -> Void = { _ in }

    /// The background Windows HID monitor.
    private lazy var monitor = WindowsHIDMonitor { [weak self] event in
        DispatchQueue.main.async { [weak self] in
            self?.eventHandler(event)
        }
    }

    /// Installs the main-actor device-event receiver.
    ///
    /// - Parameter handler: The receiver for hardware lifecycle and state events.
    func setEventHandler(
        _ handler: @escaping @MainActor @Sendable (_ event: KeyboardMonitorEvent) -> Void
    ) {
        eventHandler = handler
    }

    /// Starts Windows HID discovery.
    func start() { monitor.start() }

    /// Restarts Windows HID discovery.
    func restart() { monitor.restart() }

    /// Persists an RGB Matrix configuration to the active keyboard.
    ///
    /// - Parameter settings: The complete base-layer configuration to persist.
    func applyRGBSettings(_ settings: RGBSettings) { monitor.applyRGBSettings(settings) }

    /// Stops Windows HID discovery and releases active sessions.
    func stop() { monitor.stop() }
}
