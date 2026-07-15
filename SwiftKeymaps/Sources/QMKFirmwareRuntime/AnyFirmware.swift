import QMKKeymapKit

/// A domain-erased firmware definition used by host tooling and catalogs.
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

    /// The semantic catalog fingerprint.
    public let semanticCatalogFingerprint: UInt32

    /// The style catalog fingerprint.
    public let styleCatalogFingerprint: UInt32

    /// The stable 32-bit layout identifier carried by protocol v4.
    public let layoutID: UInt32

    /// The domain-owned semantic presentation catalog.
    public let semantics: [AnySemantic]

    /// The domain-owned visual-style presentation catalog.
    public let styles: [AnyStyle]

    /// Erases a statically typed firmware composition.
    ///
    /// - Parameter firmware: The firmware type to erase.
    public init<Firmware: QMKFirmware>(_ firmware: Firmware.Type) {
        let keymap = firmware.keymap
        let selectedFeatures = firmware.features
        id = keymap.id
        outputName = firmware.outputName
        layout = keymap.layout
        layers = keymap.layers.map(AnyFirmwareLayer.init)
        encoders = keymap.encoders.map(AnyFirmwareEncoder.init)
        buildSettings = firmware.configuration.qmkBuildSettings
            + selectedFeatures.descriptors.flatMap(\.buildSettings)
        features = selectedFeatures
        semanticCatalogFingerprint = CatalogFingerprint.semantics(Firmware.Domain.semantics)
        styleCatalogFingerprint = CatalogFingerprint.styles(Firmware.Domain.styles)
        layoutID = CatalogFingerprint.identifier(keymap.layout.id)
        semantics = Firmware.Domain.semantics.entries.map(AnySemantic.init)
        styles = Firmware.Domain.styles.entries.map(AnyStyle.init)
    }
}
