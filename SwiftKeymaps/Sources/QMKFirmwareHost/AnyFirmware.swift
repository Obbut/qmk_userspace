import QMKKeymapKit
import QMKFirmwareRuntime

/// A firmware definition resolved for host tooling.
public struct AnyFirmware: Sendable {
    /// The stable keymap identifier.
    public let id: String

    /// The stable output name used by build and flashing scripts.
    public let outputName: String

    /// The keyboard layout and physical geometry.
    public let layout: LayoutDescriptor

    /// The resolved layer declarations.
    public let layers: [AnyFirmwareLayer]

    /// The resolved encoder declarations.
    public let encoders: [AnyFirmwareEncoder]

    /// The fingerprint of automatically collected legends.
    public let legendFingerprint: UInt32

    /// The fingerprint of automatically collected style appearances.
    public let styleFingerprint: UInt32

    /// The stable 32-bit layout identifier carried by protocol v5.
    public let layoutID: UInt32

    /// Referenced legends paired with generated wire identifiers.
    public let legends: [AnyLegend]

    /// Referenced appearances paired with generated wire identifiers.
    public let styles: [AnyStyle]

    /// Erases a statically typed firmware composition.
    ///
    /// - Parameter firmware: The firmware type to erase.
    public init<Firmware: QMKFirmware>(_ firmware: Firmware.Type)
    where Firmware.Layout: HostFirmwareLayout {
        let keymap = KeymapSpec(
            id: StaticStringContent.string(firmware.id),
            layout: firmware.layout.hostDescriptor,
            keymap: firmware.keymap
        )
        let keys =
            keymap.layers.flatMap(\.keys)
            + keymap.encoders.flatMap { encoder in
                encoder.mappings.flatMap { [$0.counterclockwise, $0.clockwise] }
            }
        let metadata = GeneratedKeyMetadata(keys: keys)
        let fingerprints = FirmwareRuntime<Firmware>.metadataFingerprints()
        id = keymap.id
        outputName = StaticStringContent.string(firmware.outputName)
        layout = keymap.layout
        layers = keymap.layers.map { AnyFirmwareLayer($0, metadata: metadata) }
        encoders = keymap.encoders.map { AnyFirmwareEncoder($0, metadata: metadata) }
        legendFingerprint = fingerprints.legend
        styleFingerprint = fingerprints.style
        layoutID = KeymapMetadataFingerprint.identifier(keymap.layout.id)
        legends = metadata.legends
        styles = metadata.styles
    }
}
