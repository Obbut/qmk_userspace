import QMKKeymapKit

/// A board-specific firmware composition.
public protocol QMKFirmware: Sendable {
    /// The firmware's strongly typed layer namespace.
    associatedtype LayerID: FirmwareLayerID

    /// The statically typed keymap body specialized into this firmware.
    associatedtype KeymapBody: KeymapDefinition

    /// The allocation-free matrix mapping selected by this firmware.
    associatedtype Layout: FirmwareLayout

    /// The executable feature tuple specialized into this firmware.
    associatedtype FeatureBody: FirmwareFeatureSet

    /// The stable identifier carried by firmware metadata and companion traffic.
    static var id: FirmwareID { get }

    /// The QMK matrix mapping and physical renderer geometry.
    static var layout: Layout { get }

    /// The stable output name used by build and flashing scripts.
    static var outputName: StaticString { get }

    /// Layer and encoder declarations for this firmware.
    @Keymap static var keymap: KeymapBody { get }

    /// The custom firmware behaviors selected by the board.
    @FirmwareFeatureBuilder static var features: FeatureBody { get }
}
