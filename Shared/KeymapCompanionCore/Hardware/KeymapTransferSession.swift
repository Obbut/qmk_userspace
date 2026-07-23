/// A session that owns packet decoding and paginated keymap transfer independently of OS HID APIs.
public struct KeymapTransferSession: Sendable {
    /// The most recently validated state report.
    public private(set) var latestReport: KeyboardStateReport?

    /// The most recently validated complete keymap.
    public private(set) var latestKeymap: FirmwareKeymap?

    /// The metadata for the transfer currently in progress.
    private var keymapMetadata: KeymapMetadataReport?

    /// The entries accumulated for the transfer currently in progress.
    private var keymapEntries: [FirmwareKeymapEntry] = []

    /// Creates an idle keymap transfer session.
    public init() {}

    /// Starts a fresh firmware keymap download.
    ///
    /// - Returns: Initial keymap-metadata and retained-crash request actions.
    public mutating func start() -> [KeymapSessionAction] {
        latestReport = nil
        latestKeymap = nil
        keymapMetadata = nil
        keymapEntries.removeAll(keepingCapacity: true)
        return [
            .write(report: KeymapProtocol.makeKeymapMetadataRequest()),
            .write(report: KeymapProtocol.makeCrashReportRequest()),
        ]
    }

    /// Routes one input report through state decoding, HUD validation, and keymap pagination.
    ///
    /// - Parameter bytes: One complete Raw HID input report.
    ///
    /// - Returns: The hardware and publication actions produced by the report.
    public mutating func receive(_ bytes: [UInt8]) -> [KeymapSessionAction] {
        if let crash = KeymapProtocol.crashReport(from: bytes) {
            return [.crashReport(crash)]
        }
        if let metadata = KeymapProtocol.keymapMetadataReport(from: bytes) {
            return beginKeymapTransfer(with: metadata)
        }
        if let chunk = KeymapProtocol.keymapChunkReport(from: bytes) {
            return continueKeymapTransfer(with: chunk)
        }
        if let state = KeymapProtocol.stateReport(from: bytes) {
            latestReport = state
            guard latestKeymap?.layoutID == state.layoutID else { return [] }
            return [.state(state)]
        }
        if let trigger = KeymapProtocol.layerHUDTrigger(from: bytes) {
            guard latestKeymap?.layoutID == trigger.layoutID,
                let latestReport,
                latestReport.layoutID == trigger.layoutID,
                latestReport.layerStateMask == trigger.layerStateMask,
                latestReport.defaultLayerStateMask == trigger.defaultLayerStateMask
            else {
                return []
            }
            return [.layerHUDTrigger(trigger)]
        }
        return []
    }

    /// Returns an output report that persists an RGB Matrix configuration.
    ///
    /// - Parameter settings: The complete base-layer configuration to persist.
    ///
    /// - Returns: One complete Raw HID output report.
    public func rgbSettingsRequest(for settings: RGBSettings) -> [UInt8] {
        KeymapProtocol.makeRGBSettingsRequest(applying: settings)
    }

    /// Begins a transfer described by validated metadata.
    ///
    /// - Parameter metadata: The validated transfer metadata.
    ///
    /// - Returns: The first keymap-chunk request.
    private mutating func beginKeymapTransfer(
        with metadata: KeymapMetadataReport
    ) -> [KeymapSessionAction] {
        keymapMetadata = metadata
        keymapEntries.removeAll(keepingCapacity: true)
        keymapEntries.reserveCapacity(metadata.entryCount)
        return keymapChunkRequest(startingAt: 0)
    }

    /// Adds a validated chunk to the transfer currently in progress.
    ///
    /// - Parameter chunk: The next validated keymap chunk.
    ///
    /// - Returns: The next chunk request or completed transfer actions.
    private mutating func continueKeymapTransfer(
        with chunk: KeymapChunkReport
    ) -> [KeymapSessionAction] {
        guard let metadata = keymapMetadata,
            chunk.layoutID == metadata.layoutID,
            chunk.totalEntryCount == metadata.entryCount,
            chunk.startIndex == keymapEntries.count,
            chunk.entries.count <= metadata.entriesPerChunk
        else {
            return fail(withMessage: "Firmware returned an inconsistent keymap chunk.")
        }

        keymapEntries.append(contentsOf: chunk.entries)
        guard keymapEntries.count <= metadata.entryCount else {
            return fail(withMessage: "Firmware returned too many keymap entries.")
        }
        guard keymapEntries.count == metadata.entryCount else {
            return keymapChunkRequest(startingAt: keymapEntries.count)
        }

        let keymap = FirmwareKeymap(
            layoutID: metadata.layoutID,
            layerCount: metadata.layerCount,
            matrixRowCount: metadata.matrixRowCount,
            matrixColumnCount: metadata.matrixColumnCount,
            encoderCount: metadata.encoderCount,
            fingerprint: metadata.fingerprint,
            legendFingerprint: metadata.legendFingerprint,
            styleFingerprint: metadata.styleFingerprint,
            entries: keymapEntries
        )
        guard keymap.hasValidFingerprint else {
            return fail(withMessage: "Firmware keymap fingerprint validation failed.")
        }

        latestKeymap = keymap
        keymapMetadata = nil
        var actions: [KeymapSessionAction] = [.keymap(keymap)]
        if let latestReport, latestReport.layoutID == keymap.layoutID {
            actions.append(.state(latestReport))
        } else {
            actions.append(.write(report: KeymapProtocol.makeStateRequest()))
        }
        return actions
    }

    /// Returns a request for a page of keymap entries.
    ///
    /// - Parameter startIndex: The first layer-major entry to request.
    ///
    /// - Returns: A chunk request or a size-validation failure.
    private func keymapChunkRequest(startingAt startIndex: Int) -> [KeymapSessionAction] {
        guard let encodedIndex = UInt16(exactly: startIndex) else {
            return [.failed(message: "Firmware keymap is too large for protocol v5.")]
        }
        return [.write(report: KeymapProtocol.makeKeymapChunkRequest(startingAt: encodedIndex))]
    }

    /// Cancels the current transfer and emits a failure.
    ///
    /// - Parameter message: The user-facing failure description.
    ///
    /// - Returns: The failure action.
    private mutating func fail(withMessage message: String) -> [KeymapSessionAction] {
        keymapMetadata = nil
        keymapEntries.removeAll(keepingCapacity: true)
        return [.failed(message: message)]
    }
}
