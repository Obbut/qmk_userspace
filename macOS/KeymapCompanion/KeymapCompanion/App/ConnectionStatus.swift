/// The connection phase shown in the app's status surfaces.
enum ConnectionStatus: Equatable, Sendable {
    /// Looking for a compatible Elora or Kyria Raw HID interface.
    case searching

    /// Receiving validated state from the keyboard.
    case connected

    /// A previously connected keyboard was removed.
    case disconnected

    /// Device monitoring failed with a diagnostic message.
    case failed(String)

    /// Whether realtime keyboard state is currently available.
    var isConnected: Bool {
        self == .connected
    }
}
