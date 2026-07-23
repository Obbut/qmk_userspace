/// A state change emitted by a platform keyboard hardware client.
public enum KeyboardMonitorEvent: Equatable, Sendable {
    /// Hardware discovery started or restarted.
    case searching

    /// A validated realtime keyboard-state report arrived.
    case state(KeyboardStateReport)

    /// Firmware authorized presentation of the HUD for the current layer state.
    case layerHUDTrigger(LayerHUDTrigger)

    /// A complete, fingerprint-validated firmware keymap arrived.
    case keymap(FirmwareKeymap)

    /// The active keyboard disconnected without a replacement.
    case disconnected

    /// Hardware monitoring failed with the associated diagnostic message.
    case failed(message: String)
}
