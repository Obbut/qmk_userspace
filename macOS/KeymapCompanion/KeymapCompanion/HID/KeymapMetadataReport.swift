/// Metadata that starts a firmware keymap transfer.
struct KeymapMetadataReport: Equatable, Sendable {
    /// The keyboard model that will supply the entries.
    let keyboardKind: KeyboardKind

    /// The number of compiled QMK layers.
    let layerCount: Int

    /// The number of rows in the complete split matrix.
    let matrixRowCount: Int

    /// The number of columns in each matrix row.
    let matrixColumnCount: Int

    /// The byte count of one encoded entry.
    let entrySize: Int

    /// The maximum number of entries returned in a chunk.
    let entriesPerChunk: Int

    /// The FNV-1a fingerprint covering metadata and every entry.
    let fingerprint: UInt32

    /// The total number of matrix and encoder entries.
    let entryCount: Int

    /// The number of physical encoders represented after the matrix entries.
    let encoderCount: Int
}
