@testable import KeymapCompanionCore

/// A main-actor test double that records hardware-client interactions.
@MainActor
final class RecordingHardwareClient: KeyboardHardwareClient {
    /// The receiver installed by the model.
    private var eventHandler: @MainActor @Sendable (_ event: KeyboardMonitorEvent) -> Void = { _ in }

    /// The number of discovery starts.
    private(set) var startCount = 0

    /// The number of discovery restarts.
    private(set) var restartCount = 0

    /// The number of shutdown requests.
    private(set) var stopCount = 0

    /// The RGB configurations requested by the model.
    private(set) var appliedRGBSettings: [RGBSettings] = []

    /// Installs the model's hardware-event receiver.
    ///
    /// - Parameter handler: The receiver to install.
    func setEventHandler(
        _ handler: @escaping @MainActor @Sendable (_ event: KeyboardMonitorEvent) -> Void
    ) {
        eventHandler = handler
    }

    /// Records a discovery start.
    func start() { startCount += 1 }

    /// Records a discovery restart.
    func restart() { restartCount += 1 }

    /// Records an RGB Matrix configuration.
    ///
    /// - Parameter settings: The configuration requested by the model.
    func applyRGBSettings(_ settings: RGBSettings) { appliedRGBSettings.append(settings) }

    /// Records a shutdown request.
    func stop() { stopCount += 1 }

    /// Emits a hardware event to the installed receiver.
    ///
    /// - Parameter event: The event to emit.
    func emit(_ event: KeyboardMonitorEvent) {
        eventHandler(event)
    }
}
