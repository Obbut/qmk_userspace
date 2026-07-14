/// One ordered page of firmware keymap entries.
struct KeymapChunkReport: Equatable, Sendable {
    /// The keyboard model that supplied the page.
    let keyboardKind: KeyboardKind

    /// The zero-based entry offset of this page.
    let startIndex: Int

    /// The total entry count repeated for transfer validation.
    let totalEntryCount: Int

    /// Consecutive entries beginning at `startIndex`.
    let entries: [FirmwareKeymapEntry]
}
