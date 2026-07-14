/// The connection phase shown in companion app status surfaces.
public enum ConnectionStatus: Equatable, Sendable {
    case searching
    case connected
    case disconnected
    case failed(String)

    public var isConnected: Bool { self == .connected }
}

/// State changes emitted by a platform Raw HID monitor.
public enum KeyboardMonitorEvent: Equatable, Sendable {
    case searching
    case state(KeyboardStateReport)
    case keymap(FirmwareKeymap)
    case disconnected
    case failed(String)
}

/// Platform-neutral application state and event reduction shared by native UIs.
public struct CompanionState: Equatable, Sendable {
    public private(set) var connectionStatus: ConnectionStatus = .searching
    public private(set) var keyboardKind: KeyboardKind?
    public private(set) var keymapDefinition: KeymapDefinition?
    public private(set) var layerStateMask: UInt32 = 1
    public private(set) var defaultLayerStateMask: UInt32 = 1
    public private(set) var latestSequence: UInt32 = 0
    public private(set) var capabilities: UInt32 = 0
    public private(set) var rgbSettings: RGBSettings = .default

    public init() {}

    public init(
        connectionStatus: ConnectionStatus,
        keyboardKind: KeyboardKind?,
        keymapDefinition: KeymapDefinition?,
        layerStateMask: UInt32,
        defaultLayerStateMask: UInt32,
        latestSequence: UInt32 = 0,
        capabilities: UInt32,
        rgbSettings: RGBSettings
    ) {
        self.connectionStatus = connectionStatus
        self.keyboardKind = keyboardKind
        self.keymapDefinition = keymapDefinition
        self.layerStateMask = layerStateMask
        self.defaultLayerStateMask = defaultLayerStateMask
        self.latestSequence = latestSequence
        self.capabilities = capabilities
        self.rgbSettings = rgbSettings
    }

    public var effectiveLayerMask: UInt32 {
        layerStateMask | defaultLayerStateMask
    }

    public var activeLayer: KeymapLayer {
        KeymapLayer.highestActiveLayer(in: effectiveLayerMask)
    }

    public var supportsRGBSettings: Bool {
        connectionStatus.isConnected
            && capabilities & KeymapProtocol.rgbSettingsCapability != 0
    }

    /// Applies one transport event and returns whether visible state changed.
    @discardableResult
    public mutating func apply(
        _ event: KeyboardMonitorEvent,
        acceptRGBSettings: Bool = true
    ) -> Bool {
        let previous = self
        switch event {
        case .searching:
            connectionStatus = .searching
            keyboardKind = nil
            keymapDefinition = nil
            capabilities = 0

        case let .keymap(firmwareKeymap):
            guard let definition = KeymapDefinition(firmwareKeymap: firmwareKeymap) else {
                connectionStatus = .failed(
                    "Firmware matrix does not match the supported keyboard geometry."
                )
                return previous != self
            }
            keyboardKind = firmwareKeymap.keyboardKind
            keymapDefinition = definition

        case let .state(report):
            guard keymapDefinition?.keyboardKind == report.keyboardKind else { return false }
            keyboardKind = report.keyboardKind
            layerStateMask = report.layerStateMask
            defaultLayerStateMask = report.defaultLayerStateMask
            latestSequence = report.sequence
            capabilities = report.capabilities
            if acceptRGBSettings, let rgbSettings = report.rgbSettings {
                self.rgbSettings = rgbSettings
            }
            connectionStatus = .connected

        case .disconnected:
            connectionStatus = .disconnected
            capabilities = 0

        case let .failed(message):
            connectionStatus = .failed(message)
            capabilities = 0
        }
        return previous != self
    }

    /// Updates optimistic RGB UI state while the transport waits for firmware acknowledgement.
    public mutating func setRGBSettings(_ settings: RGBSettings) {
        rgbSettings = settings
    }
}
