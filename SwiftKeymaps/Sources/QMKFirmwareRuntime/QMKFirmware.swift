import QMKKeymapKit

/// A board-specific firmware composition rooted in one keymap domain.
public protocol QMKFirmware<Domain>: Sendable {
    /// The semantic and style domain selected by the firmware.
    associatedtype Domain: KeymapDomain

    /// The concrete keymap specification type.
    associatedtype Keymap: KeymapSpecification<Domain>

    /// The stable output name used by build and flashing scripts.
    static var outputName: String { get }

    /// The board's complete typed keymap.
    static var keymap: Keymap { get }

    /// The generated QMK build configuration.
    static var configuration: QMKConfiguration { get }

    /// The custom firmware behaviors selected by the board.
    @FirmwareFeatureBuilder static var features: FirmwareFeatures { get }
}
