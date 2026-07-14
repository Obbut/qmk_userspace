/// An action produced by the platform-neutral Raw HID protocol session.
public enum KeymapSessionAction: Equatable, Sendable {
    /// Write a complete output report to the active HID endpoint.
    case write([UInt8])

    /// Publish a complete firmware-owned keymap.
    case keymap(FirmwareKeymap)

    /// Publish validated keyboard state after its matching keymap is available.
    case state(KeyboardStateReport)

    /// Surface a malformed or inconsistent firmware transfer.
    case failed(String)
}

/// Owns packet decoding and the paginated keymap transfer independently of the OS HID API.
public struct KeymapTransferSession: Sendable {
    public private(set) var latestReport: KeyboardStateReport?
    public private(set) var latestKeymap: FirmwareKeymap?

    private var keymapMetadata: KeymapMetadataReport?
    private var keymapEntries: [FirmwareKeymapEntry] = []

    public init() {}

    /// Starts a fresh firmware keymap download.
    public mutating func start() -> [KeymapSessionAction] {
        latestReport = nil
        latestKeymap = nil
        keymapMetadata = nil
        keymapEntries.removeAll(keepingCapacity: true)
        return [.write(KeymapProtocol.makeKeymapMetadataRequest())]
    }

    /// Routes one input report through state decoding and keymap pagination.
    public mutating func receive(_ bytes: [UInt8]) -> [KeymapSessionAction] {
        if let metadata = KeymapProtocol.parseKeymapMetadataReport(bytes) {
            return beginKeymapTransfer(metadata)
        }
        if let chunk = KeymapProtocol.parseKeymapChunkReport(bytes) {
            return continueKeymapTransfer(chunk)
        }
        if let state = KeymapProtocol.parseStateReport(bytes) {
            latestReport = state
            guard latestKeymap?.keyboardKind == state.keyboardKind else { return [] }
            return [.state(state)]
        }
        return []
    }

    /// Creates a complete RGB settings output report.
    public func rgbSettingsRequest(_ settings: RGBSettings) -> [UInt8] {
        KeymapProtocol.makeRGBSettingsRequest(settings)
    }

    private mutating func beginKeymapTransfer(
        _ metadata: KeymapMetadataReport
    ) -> [KeymapSessionAction] {
        keymapMetadata = metadata
        keymapEntries.removeAll(keepingCapacity: true)
        keymapEntries.reserveCapacity(metadata.entryCount)
        return requestKeymapChunk(startingAt: 0)
    }

    private mutating func continueKeymapTransfer(
        _ chunk: KeymapChunkReport
    ) -> [KeymapSessionAction] {
        guard let metadata = keymapMetadata,
              chunk.keyboardKind == metadata.keyboardKind,
              chunk.totalEntryCount == metadata.entryCount,
              chunk.startIndex == keymapEntries.count,
              chunk.entries.count <= metadata.entriesPerChunk else {
            return fail("Firmware returned an inconsistent keymap chunk.")
        }

        keymapEntries.append(contentsOf: chunk.entries)
        guard keymapEntries.count <= metadata.entryCount else {
            return fail("Firmware returned too many keymap entries.")
        }
        guard keymapEntries.count == metadata.entryCount else {
            return requestKeymapChunk(startingAt: keymapEntries.count)
        }

        let keymap = FirmwareKeymap(
            keyboardKind: metadata.keyboardKind,
            layerCount: metadata.layerCount,
            matrixRowCount: metadata.matrixRowCount,
            matrixColumnCount: metadata.matrixColumnCount,
            encoderCount: metadata.encoderCount,
            fingerprint: metadata.fingerprint,
            entries: keymapEntries
        )
        guard keymap.hasValidFingerprint else {
            return fail("Firmware keymap fingerprint validation failed.")
        }

        latestKeymap = keymap
        keymapMetadata = nil
        var actions: [KeymapSessionAction] = [.keymap(keymap)]
        if let latestReport, latestReport.keyboardKind == keymap.keyboardKind {
            actions.append(.state(latestReport))
        } else {
            actions.append(.write(KeymapProtocol.makeStateRequest()))
        }
        return actions
    }

    private func requestKeymapChunk(startingAt startIndex: Int) -> [KeymapSessionAction] {
        guard let encodedIndex = UInt16(exactly: startIndex) else {
            return [.failed("Firmware keymap is too large for protocol v3.")]
        }
        return [.write(KeymapProtocol.makeKeymapChunkRequest(startingAt: encodedIndex))]
    }

    private mutating func fail(_ message: String) -> [KeymapSessionAction] {
        keymapMetadata = nil
        keymapEntries.removeAll(keepingCapacity: true)
        return [.failed(message)]
    }
}
