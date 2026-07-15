import QMKKeymapKit

/// A board-specific firmware composition rooted in one keymap domain.
public protocol QMKFirmware<Domain>: Sendable {
    /// The semantic and style domain selected by the firmware.
    associatedtype Domain: KeymapDomain

    /// The stable identifier carried by generated metadata and companion traffic.
    static var id: String { get }

    /// The QMK matrix mapping and physical renderer geometry.
    static var layout: LayoutDescriptor { get }

    /// The stable output name used by build and flashing scripts.
    static var outputName: String { get }

    /// Layer and encoder declarations for this firmware.
    @KeymapBuilder<Domain> static var keymap: Keymap<Domain> { get }

    /// The generated QMK build configuration.
    static var configuration: QMKConfiguration { get }

    /// The custom firmware behaviors selected by the board.
    @FirmwareFeatureBuilder static var features: FirmwareFeatures { get }
}
