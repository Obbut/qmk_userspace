import QMKKeymapKit

/// A firmware definition resolved for generation and host tooling.
public struct AnyFirmware: Sendable {
    /// The stable keymap identifier.
    public let id: String

    /// The stable output name used by build and flashing scripts.
    public let outputName: String

    /// The keyboard layout and physical geometry.
    public let layout: LayoutDescriptor

    /// The generated C layer declarations.
    public let layers: [AnyFirmwareLayer]

    /// The generated C encoder declarations.
    public let encoders: [AnyFirmwareEncoder]

    /// The generated QMK build configuration.
    public let buildSettings: [QMKBuildSetting]

    /// The selected firmware features.
    public let features: FirmwareFeatures

    /// The fingerprint of automatically collected semantic metadata.
    public let semanticFingerprint: UInt32

    /// The fingerprint of automatically collected style appearances.
    public let styleFingerprint: UInt32

    /// The stable 32-bit layout identifier carried by protocol v4.
    public let layoutID: UInt32

    /// Referenced semantics paired with generated wire identifiers.
    public let semantics: [AnySemantic]

    /// Referenced appearances paired with generated wire identifiers.
    public let styles: [AnyStyle]

    /// Erases a statically typed firmware composition.
    ///
    /// - Parameter firmware: The firmware type to erase.
    public init<Firmware: QMKFirmware>(_ firmware: Firmware.Type) {
        let keymap = KeymapSpec(
            id: firmware.id,
            layout: firmware.layout,
            keymap: firmware.keymap
        )
        let selectedFeatures = firmware.features
        let keys =
            keymap.layers.flatMap(\.keys)
            + keymap.encoders.flatMap { encoder in
                encoder.mappings.flatMap { [$0.counterclockwise, $0.clockwise] }
            }
        let metadata = GeneratedKeyMetadata(keys: keys)
        id = keymap.id
        outputName = firmware.outputName
        layout = keymap.layout
        layers = keymap.layers.map { AnyFirmwareLayer($0, metadata: metadata) }
        encoders = keymap.encoders.map { AnyFirmwareEncoder($0, metadata: metadata) }
        buildSettings =
            firmware.configuration.qmkBuildSettings
            + selectedFeatures.descriptors.flatMap(\.buildSettings)
        features = selectedFeatures
        semanticFingerprint = metadata.semanticFingerprint
        styleFingerprint = metadata.styleFingerprint
        layoutID = KeymapMetadataFingerprint.identifier(keymap.layout.id)
        semantics = metadata.semantics
        styles = metadata.styles
    }
}
