/// An action produced by the platform-neutral Raw HID protocol session.
public enum KeymapSessionAction: Equatable, Sendable {
    /// A complete output report for the active HID endpoint.
    case write(report: [UInt8])

    /// A complete firmware-owned keymap ready for publication.
    case keymap(FirmwareKeymap)

    /// Validated keyboard state ready for publication after its matching keymap.
    case state(KeyboardStateReport)

    /// A malformed or inconsistent firmware-transfer failure.
    case failed(message: String)
}
