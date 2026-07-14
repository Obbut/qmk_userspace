import Observation

/// Main-actor application state shared by the window and menu-bar scenes.
@MainActor
@Observable
final class AppModel {
    /// The current device-monitoring phase.
    private(set) var connectionStatus: ConnectionStatus = .searching

    /// The last compatible keyboard that sent a validated packet.
    private(set) var keyboardKind: KeyboardKind?

    /// The current QMK layer-state mask.
    private(set) var layerStateMask: UInt32 = 1

    /// The current QMK default-layer-state mask.
    private(set) var defaultLayerStateMask: UInt32 = 1

    /// The latest firmware packet sequence, useful for future diagnostics.
    private(set) var latestSequence: UInt32 = 0

    /// The capabilities advertised by the connected firmware.
    private(set) var capabilities: UInt32 = 0

    /// The long-lived HID monitor that outlives every app window.
    @ObservationIgnored private let monitor: KeyboardHIDMonitor

    /// Creates app state and immediately begins monitoring on the main run loop.
    /// - Parameter monitor: The HID monitor to retain for the application's lifetime.
    init(monitor: KeyboardHIDMonitor = KeyboardHIDMonitor()) {
        self.monitor = monitor
        monitor.eventHandler = { [weak self] event in
            self?.receive(event)
        }
        monitor.start()
    }

    /// The union needed to resolve transparent QMK mappings.
    var effectiveLayerMask: UInt32 {
        layerStateMask | defaultLayerStateMask
    }

    /// The highest layer currently visible to the user.
    var activeLayer: KeymapLayer {
        KeymapLayer.highestActiveLayer(in: effectiveLayerMask)
    }

    /// Restarts discovery and requests fresh state from matching devices.
    func reconnect() {
        connectionStatus = .searching
        monitor.restart()
    }

    /// Applies a device-monitor event to observable UI state.
    /// - Parameter event: The event emitted by the monitor.
    private func receive(_ event: KeyboardMonitorEvent) {
        switch event {
        case .searching:
            connectionStatus = .searching
        case let .state(report):
            keyboardKind = report.keyboardKind
            layerStateMask = report.layerStateMask
            defaultLayerStateMask = report.defaultLayerStateMask
            latestSequence = report.sequence
            capabilities = report.capabilities
            connectionStatus = .connected
        case .disconnected:
            connectionStatus = .disconnected
        case let .failed(message):
            connectionStatus = .failed(message)
        }
    }

#if DEBUG
    /// Creates deterministic app state for previews without opening the HID manager.
    /// - Parameters:
    ///   - connectionStatus: The connection phase to render.
    ///   - keyboardKind: The keyboard model to render, or `nil` for the waiting state.
    ///   - activeLayers: Nondefault layers whose bits should be active.
    /// - Returns: A preview-only model that performs no device discovery.
    static func preview(
        connectionStatus: ConnectionStatus = .connected,
        keyboardKind: KeyboardKind? = .elora,
        activeLayers: [KeymapLayer] = []
    ) -> AppModel {
        AppModel(
            previewConnectionStatus: connectionStatus,
            keyboardKind: keyboardKind,
            activeLayers: activeLayers
        )
    }

    /// Creates preview state while deliberately leaving its HID monitor stopped.
    /// - Parameters:
    ///   - previewConnectionStatus: The connection phase to render.
    ///   - keyboardKind: The keyboard model to render.
    ///   - activeLayers: Nondefault layers whose bits should be active.
    private init(
        previewConnectionStatus: ConnectionStatus,
        keyboardKind: KeyboardKind?,
        activeLayers: [KeymapLayer]
    ) {
        monitor = KeyboardHIDMonitor()
        connectionStatus = previewConnectionStatus
        self.keyboardKind = keyboardKind
        layerStateMask = activeLayers.reduce(into: UInt32.zero) { mask, layer in
            mask |= UInt32(1) << UInt32(layer.rawValue)
        }
        defaultLayerStateMask = UInt32(1) << UInt32(KeymapLayer.base.rawValue)
        capabilities = 1
    }
#endif
}
