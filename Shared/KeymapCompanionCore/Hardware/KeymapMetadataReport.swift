/// Metadata that begins a firmware keymap transfer.
public struct KeymapMetadataReport: Equatable, Sendable {
    /// The keyboard model represented by the transfer.
    public let keyboardKind: KeyboardKind

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

    /// The complete number of matrix and encoder entries.
    public let entryCount: Int

    /// The number of physical encoders represented after matrix entries.
    public let encoderCount: Int

    /// Creates validated keymap-transfer metadata.
    ///
    /// - Parameters:
    ///   - keyboardKind: The keyboard model represented by the transfer.
    ///   - layerCount: The number of keymap layers.
    ///   - matrixRowCount: The number of matrix rows per layer.
    ///   - matrixColumnCount: The number of matrix columns per layer.
    ///   - entryByteCount: The byte count of one encoded keymap entry.
    ///   - entriesPerChunk: The maximum number of entries in one chunk report.
    ///   - fingerprint: The firmware-computed keymap fingerprint.
    ///   - entryCount: The complete number of matrix and encoder entries.
    ///   - encoderCount: The number of physical encoders represented after matrix entries.
    public init(
        keyboardKind: KeyboardKind,
        layerCount: Int,
        matrixRowCount: Int,
        matrixColumnCount: Int,
        entryByteCount: Int,
        entriesPerChunk: Int,
        fingerprint: UInt32,
        entryCount: Int,
        encoderCount: Int
    ) {
        self.keyboardKind = keyboardKind
        self.layerCount = layerCount
        self.matrixRowCount = matrixRowCount
        self.matrixColumnCount = matrixColumnCount
        self.entryByteCount = entryByteCount
        self.entriesPerChunk = entriesPerChunk
        self.fingerprint = fingerprint
        self.entryCount = entryCount
        self.encoderCount = encoderCount
    }
}
