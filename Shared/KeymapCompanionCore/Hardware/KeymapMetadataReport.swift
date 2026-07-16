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

    /// The fingerprint of legend metadata generated for the firmware.
    public let legendFingerprint: UInt32

    /// The fingerprint of style metadata generated for the firmware.
    public let styleFingerprint: UInt32

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
    ///   - legendFingerprint: The firmware legend-metadata fingerprint.
    ///   - styleFingerprint: The firmware style-metadata fingerprint.
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
        legendFingerprint: UInt32,
        styleFingerprint: UInt32,
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
        self.legendFingerprint = legendFingerprint
        self.styleFingerprint = styleFingerprint
        self.entryCount = entryCount
        self.encoderCount = encoderCount
    }
}
