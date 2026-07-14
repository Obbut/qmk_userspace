/// State changes emitted by the Raw HID device monitor.
enum KeyboardMonitorEvent: Equatable, Sendable {
    /// The monitor is looking for a compatible Raw HID endpoint.
    case searching

    /// A validated keyboard state arrived.
    case state(KeyboardStateReport)

    /// The active compatible keyboard was disconnected.
    case disconnected

    /// The monitor could not start or open a matching endpoint.
    case failed(String)
}
