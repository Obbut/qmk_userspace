/// Platform-neutral application state and event reduction shared by native UIs.
struct CompanionState: Equatable, Sendable {
    /// The current device-monitoring phase.
    private(set) var connectionStatus: ConnectionStatus = .searching

    /// The last compatible keyboard that sent a validated report.
    private(set) var layoutID: LayoutID?

    /// The visual keymap built from the downloaded firmware matrix.
    private(set) var keymapDefinition: KeymapDefinition?

    /// The current nonpersistent QMK layer-state mask.
    private(set) var layerStateMask: UInt32 = 1

    /// The current persistent QMK default-layer-state mask.
    private(set) var defaultLayerStateMask: UInt32 = 1

    /// The sequence number from the latest accepted state report.
    private(set) var latestSequence: UInt32 = 0

    /// The capability bits advertised by the connected firmware.
    private(set) var capabilities: UInt32 = 0

    /// The latest accepted or optimistically edited lighting configuration.
    private(set) var rgbSettings: RGBSettings = .default

    /// Creates state that is ready to begin keyboard discovery.
    init() {}

    /// Creates state with explicit transport and presentation values.
    ///
    /// - Parameters:
    ///   - connectionStatus: The current device-monitoring phase.
    ///   - layoutID: The connected keyboard layout, if known.
    ///   - keymapDefinition: The downloaded visual keymap, if available.
    ///   - layerStateMask: The nonpersistent QMK layer-state mask.
    ///   - defaultLayerStateMask: The persistent QMK default-layer-state mask.
    ///   - latestSequence: The sequence number from the latest accepted state report.
    ///   - capabilities: The capability bits advertised by the firmware.
    ///   - rgbSettings: The current lighting configuration.
    init(
        connectionStatus: ConnectionStatus,
        layoutID: LayoutID?,
        keymapDefinition: KeymapDefinition?,
        layerStateMask: UInt32,
        defaultLayerStateMask: UInt32,
        latestSequence: UInt32 = 0,
        capabilities: UInt32,
        rgbSettings: RGBSettings
    ) {
        self.connectionStatus = connectionStatus
        self.layoutID = layoutID
        self.keymapDefinition = keymapDefinition
        self.layerStateMask = layerStateMask
        self.defaultLayerStateMask = defaultLayerStateMask
        self.latestSequence = latestSequence
        self.capabilities = capabilities
        self.rgbSettings = rgbSettings
    }

    /// The effective QMK layer mask used to resolve transparent mappings.
    var effectiveLayerMask: UInt32 {
        layerStateMask | defaultLayerStateMask
    }

    /// The highest layer in the effective layer stack.
    var activeLayer: KeymapLayer {
        keymapDefinition?.highestActiveLayer(in: effectiveLayerMask) ?? .base
    }

    /// Whether the connected firmware supports explicit lighting settings.
    var supportsRGBSettings: Bool {
        connectionStatus.isConnected
            && capabilities & KeymapProtocol.rgbSettingsCapability != 0
    }

    /// Applies a transport event and returns whether state changed.
    ///
    /// - Parameters:
    ///   - event: The event emitted by a platform hardware client.
    ///   - acceptRGBSettings: Whether reported lighting settings may replace local edits.
    /// - Returns: `true` when applying the event changed at least one stored value.
    @discardableResult
    mutating func apply(
        _ event: KeyboardMonitorEvent,
        acceptRGBSettings: Bool = true
    ) -> Bool {
        let previous = self
        switch event {
        case .searching:
            connectionStatus = .searching
            layoutID = nil
            keymapDefinition = nil
            capabilities = 0

        case let .keymap(firmwareKeymap):
            guard let definition = KeymapDefinition(firmwareKeymap: firmwareKeymap) else {
                connectionStatus = .failed(
                    message: "Firmware matrix does not match the supported keyboard geometry."
                )
                return previous != self
            }
            layoutID = firmwareKeymap.layoutID
            keymapDefinition = definition

        case let .state(report):
            guard keymapDefinition?.layoutID == report.layoutID else { return false }
            layoutID = report.layoutID
            layerStateMask = report.layerStateMask
            defaultLayerStateMask = report.defaultLayerStateMask
            latestSequence = report.sequence
            capabilities = report.capabilities
            if acceptRGBSettings, let rgbSettings = report.rgbSettings {
                self.rgbSettings = rgbSettings
            }
            connectionStatus = .connected

        case .layerHUDTrigger:
            break

        case .disconnected:
            connectionStatus = .disconnected
            capabilities = 0

        case let .failed(message):
            connectionStatus = .failed(message: message)
            capabilities = 0
        }
        return previous != self
    }

    /// Updates optimistic lighting state while transport waits for firmware acknowledgement.
    ///
    /// - Parameter settings: The locally edited lighting configuration.
    mutating func setRGBSettings(_ settings: RGBSettings) {
        rgbSettings = settings
    }
}
