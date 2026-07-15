/// Metadata that begins a firmware keymap transfer.
public struct KeymapMetadataReport: Equatable, Sendable {
    /// The opaque keyboard layout represented by the transfer.
    public let layoutID: LayoutID

    /// The number of keymap layers.
    public let layerCount: Int

    /// The number of matrix rows per layer.
    public let matrixRowCount: Int

    /// The number of matrix columns per layer.
    public let matrixColumnCount: Int

    /// The byte count of one encoded keymap entry.
    public let entryByteCount: Int

    /// The maximum number of entries in one chunk report.
    public let entriesPerChunk: Int

    /// The firmware-computed keymap fingerprint.
    public let fingerprint: UInt32

    /// The fingerprint of the semantic catalog used by the firmware.
    public let semanticCatalogFingerprint: UInt32

    /// The fingerprint of the style catalog used by the firmware.
    public let styleCatalogFingerprint: UInt32

    /// The complete number of matrix and encoder entries.
    public let entryCount: Int

    /// The number of physical encoders represented after matrix entries.
    public let encoderCount: Int

    /// Creates validated keymap-transfer metadata.
    ///
    /// - Parameters:
    ///   - layoutID: The opaque keyboard layout represented by the transfer.
    ///   - layerCount: The number of keymap layers.
    ///   - matrixRowCount: The number of matrix rows per layer.
    ///   - matrixColumnCount: The number of matrix columns per layer.
    ///   - entryByteCount: The byte count of one encoded keymap entry.
    ///   - entriesPerChunk: The maximum number of entries in one chunk report.
    ///   - fingerprint: The firmware-computed keymap fingerprint.
    ///   - semanticCatalogFingerprint: The firmware semantic-catalog fingerprint.
    ///   - styleCatalogFingerprint: The firmware style-catalog fingerprint.
    ///   - entryCount: The complete number of matrix and encoder entries.
    ///   - encoderCount: The number of physical encoders represented after matrix entries.
    init(
        layoutID: LayoutID,
        layerCount: Int,
        matrixRowCount: Int,
        matrixColumnCount: Int,
        entryByteCount: Int,
        entriesPerChunk: Int,
        fingerprint: UInt32,
        semanticCatalogFingerprint: UInt32,
        styleCatalogFingerprint: UInt32,
        entryCount: Int,
        encoderCount: Int
    ) {
        self.layoutID = layoutID
        self.layerCount = layerCount
        self.matrixRowCount = matrixRowCount
        self.matrixColumnCount = matrixColumnCount
        self.entryByteCount = entryByteCount
        self.entriesPerChunk = entriesPerChunk
        self.fingerprint = fingerprint
        self.semanticCatalogFingerprint = semanticCatalogFingerprint
        self.styleCatalogFingerprint = styleCatalogFingerprint
        self.entryCount = entryCount
        self.encoderCount = encoderCount
    }
}
