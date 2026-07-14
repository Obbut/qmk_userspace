import Dependencies

/// The common hardware boundary used by the shared companion model.
///
/// Each native app supplies its own implementation. All methods are main-actor
/// entry points even when an implementation performs its HID work on a private
/// queue.
public protocol KeyboardHardwareClient: AnyObject, Sendable {
    @MainActor
    func setEventHandler(
        _ handler: @escaping @MainActor @Sendable (KeyboardMonitorEvent) -> Void
    )

    @MainActor func start()
    @MainActor func restart()
    @MainActor func applyRGBSettings(_ settings: RGBSettings)
    @MainActor func stop()
}

/// The dependency key is declared with the interface so platform targets can
/// inject live implementations without the shared package importing OS APIs.
public enum KeyboardHardwareClientKey: TestDependencyKey {
    public static let previewValue: any KeyboardHardwareClient = InertKeyboardHardwareClient()
    public static let testValue: any KeyboardHardwareClient = InertKeyboardHardwareClient()
}

public extension DependencyValues {
    var keyboardHardware: any KeyboardHardwareClient {
        get { self[KeyboardHardwareClientKey.self] }
        set { self[KeyboardHardwareClientKey.self] = newValue }
    }
}

private final class InertKeyboardHardwareClient: KeyboardHardwareClient, @unchecked Sendable {
    @MainActor
    func setEventHandler(
        _ handler: @escaping @MainActor @Sendable (KeyboardMonitorEvent) -> Void
    ) {}

    @MainActor func start() {}
    @MainActor func restart() {}
    @MainActor func applyRGBSettings(_ settings: RGBSettings) {}
    @MainActor func stop() {}
}
