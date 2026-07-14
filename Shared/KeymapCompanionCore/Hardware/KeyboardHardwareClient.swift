import Dependencies

/// The common hardware boundary used by the shared companion model.
///
/// Each native app supplies its own implementation. All methods are main-actor
/// entry points even when an implementation performs its HID work on a private
/// queue.
public protocol KeyboardHardwareClient: AnyObject, Sendable {
    /// Installs the main-actor event receiver.
    ///
    /// - Parameter handler: The receiver for hardware lifecycle and state events.
    @MainActor
    func setEventHandler(
        _ handler: @escaping @MainActor @Sendable (_ event: KeyboardMonitorEvent) -> Void
    )

    /// Starts keyboard discovery and state transfer.
    @MainActor func start()

    /// Restarts keyboard discovery and state transfer.
    @MainActor func restart()

    /// Persists an RGB Matrix configuration to the connected keyboard.
    ///
    /// - Parameter settings: The complete base-layer configuration to persist.
    @MainActor func applyRGBSettings(_ settings: RGBSettings)

    /// Stops hardware access and releases platform resources.
    @MainActor func stop()
}

/// The dependency key is declared with the interface so platform targets can
/// inject live implementations without the shared package importing OS APIs.
fileprivate enum KeyboardHardwareClientKey: TestDependencyKey {
    /// The inert client used by previews.
    static let previewValue: any KeyboardHardwareClient = InertKeyboardHardwareClient()

    /// The inert client used unless a test overrides the dependency.
    static let testValue: any KeyboardHardwareClient = InertKeyboardHardwareClient()
}

/// DependencyValues access to the platform keyboard hardware client.
public extension DependencyValues {
    /// The platform hardware boundary used by the companion model.
    var keyboardHardware: any KeyboardHardwareClient {
        get { self[KeyboardHardwareClientKey.self] }
        set { self[KeyboardHardwareClientKey.self] = newValue }
    }
}

/// A no-op hardware implementation for previews and unconfigured tests.
fileprivate final class InertKeyboardHardwareClient: KeyboardHardwareClient, @unchecked Sendable {
    /// Ignores an event receiver.
    ///
    /// - Parameter handler: The unused receiver.
    @MainActor
    func setEventHandler(
        _ handler: @escaping @MainActor @Sendable (_ event: KeyboardMonitorEvent) -> Void
    ) {}

    /// Performs no discovery.
    @MainActor func start() {}

    /// Performs no discovery restart.
    @MainActor func restart() {}

    /// Ignores an RGB Matrix configuration.
    ///
    /// - Parameter settings: The unused configuration.
    @MainActor func applyRGBSettings(_ settings: RGBSettings) {}

    /// Performs no shutdown work.
    @MainActor func stop() {}
}
