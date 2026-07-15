/// An ordered page of firmware keymap entries.
public struct KeymapChunkReport: Equatable, Sendable {
    /// The opaque keyboard layout represented by the transfer.
    public let layoutID: LayoutID

    /// The layer-major index of the first entry in this page.
    public let startIndex: Int

    /// The complete entry count advertised by transfer metadata.
    public let totalEntryCount: Int

    /// The consecutive entries in this page.
    public let entries: [FirmwareKeymapEntry]

    /// Creates a validated keymap page.
    ///
    /// - Parameters:
    ///   - layoutID: The opaque keyboard layout represented by the transfer.
    ///   - startIndex: The layer-major index of the first entry in this page.
    ///   - totalEntryCount: The complete entry count advertised by transfer metadata.
    ///   - entries: The consecutive entries in this page.
    init(
        layoutID: LayoutID,
        startIndex: Int,
        totalEntryCount: Int,
        entries: [FirmwareKeymapEntry]
    ) {
        self.layoutID = layoutID
        self.startIndex = startIndex
        self.totalEntryCount = totalEntryCount
        self.entries = entries
    }
}
