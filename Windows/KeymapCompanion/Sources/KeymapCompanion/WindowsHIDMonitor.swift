import Dispatch
import Foundation
import KeymapCompanionCore

/// A serially coordinated monitor for compatible Windows Raw HID endpoints.
///
/// All mutable monitor state is confined to ``queue``. Individual sessions own their
/// blocking read and serialized write paths independently.
final class WindowsHIDMonitor: @unchecked Sendable {
    /// A receiver for hardware lifecycle and state events.
    typealias EventHandler = @Sendable (_ event: KeyboardMonitorEvent) -> Void

    /// The receiver for hardware lifecycle and state events.
    private let eventHandler: EventHandler

    /// The serial queue that confines monitor state.
    private let queue = DispatchQueue(label: "KeymapCompanion.WindowsHIDMonitor")

    /// The periodic device-enumeration timer.
    private var timer: DispatchSourceTimer?

    /// Open sessions keyed by Windows device path.
    private var sessions: [String: WindowsHIDSession] = [:]

    /// The path currently supplying visible keyboard state.
    private var activePath: String?

    /// Creates a Windows HID monitor.
    ///
    /// - Parameter eventHandler: The receiver for hardware lifecycle and state events.
    init(eventHandler: @escaping EventHandler) {
        self.eventHandler = eventHandler
    }

    /// Starts periodic compatible-device discovery.
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

    /// Closes existing sessions and immediately starts a fresh discovery pass.
    func restart() {
        queue.async { [self] in
            for session in sessions.values {
                session.close()
            }
            sessions.removeAll()
            activePath = nil
            eventHandler(.searching)
            scan()
        }
    }

    /// Stops discovery and closes every active HID session.
    func stop() {
        queue.async { [self] in
            timer?.cancel()
            timer = nil
            for session in sessions.values {
                session.close()
            }
            sessions.removeAll()
            activePath = nil
        }
    }

    /// Persists an RGB Matrix configuration to the active keyboard.
    ///
    /// - Parameter settings: The complete base-layer configuration to persist.
    func applyRGBSettings(_ settings: RGBSettings) {
        queue.async { [self] in
            guard let activePath, let session = sessions[activePath] else { return }
            session.applyRGBSettings(settings)
        }
    }

    /// Reconciles open sessions with the currently enumerated device paths.
    private func scan() {
        let descriptors = WindowsHIDDescriptor.allCompatibleDevices()
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
            guard let transport = descriptor.makeTransport() else { continue }
            let session = WindowsHIDSession(
                path: descriptor.path,
                transport: transport,
                eventHandler: { [weak self, path = descriptor.path] event in
                    guard let monitor = self else { return }
                    monitor.queue.async { monitor.receive(event, fromDeviceAt: path) }
                }
            )
            sessions[descriptor.path] = session
            session.start()
        }
    }

    /// Publishes an event received from an open device session.
    ///
    /// - Parameters:
    ///   - event: The validated session event.
    ///   - path: The device path that produced the event.
    private func receive(_ event: KeyboardMonitorEvent, fromDeviceAt path: String) {
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

    /// Selects a fully initialized replacement session or publishes disconnection.
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
