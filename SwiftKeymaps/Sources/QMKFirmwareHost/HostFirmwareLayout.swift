import QMKKeymapKit

/// Host-only presentation paired with an embedded-safe matrix layout.
public protocol HostFirmwareLayout: FirmwareLayout {
    /// Display geometry used by previews, documentation, and companion apps.
    var hostDescriptor: LayoutDescriptor { get }
}
