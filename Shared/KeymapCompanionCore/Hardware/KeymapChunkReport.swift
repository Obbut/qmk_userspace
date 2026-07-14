/// An ordered page of firmware keymap entries.
public struct KeymapChunkReport: Equatable, Sendable {
    /// The keyboard model represented by the transfer.
    public let keyboardKind: KeyboardKind

    /// The layer-major index of the first entry in this page.
    public let startIndex: Int

    /// The complete entry count advertised by transfer metadata.
    public let totalEntryCount: Int

    /// The consecutive entries in this page.
    public let entries: [FirmwareKeymapEntry]

    /// Creates a validated keymap page.
    ///
    /// - Parameters:
    ///   - keyboardKind: The keyboard model represented by the transfer.
    ///   - startIndex: The layer-major index of the first entry in this page.
    ///   - totalEntryCount: The complete entry count advertised by transfer metadata.
    ///   - entries: The consecutive entries in this page.
    public init(
        keyboardKind: KeyboardKind,
        startIndex: Int,
        totalEntryCount: Int,
        entries: [FirmwareKeymapEntry]
    ) {
        self.keyboardKind = keyboardKind
        self.startIndex = startIndex
        self.totalEntryCount = totalEntryCount
        self.entries = entries
    }
}
