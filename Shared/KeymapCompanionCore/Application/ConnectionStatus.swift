/// The connection phase shown in companion app status surfaces.
public enum ConnectionStatus: Equatable, Sendable {
    /// The hardware client is looking for a compatible keyboard.
    case searching

    /// A compatible keyboard is providing validated state.
    case connected

    /// A previously connected keyboard is no longer available.
    case disconnected

    /// Hardware monitoring failed with the associated diagnostic message.
    case failed(message: String)

    /// Whether realtime keyboard state is available.
    public var isConnected: Bool { self == .connected }
}
