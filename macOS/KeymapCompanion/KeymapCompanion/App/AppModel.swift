import Observation

/// Main-actor application state shared by the window and menu-bar scenes.
@MainActor
@Observable
final class AppModel {
    /// The current device-monitoring phase.
    private(set) var connectionStatus: ConnectionStatus = .searching

    /// The last compatible keyboard that sent a validated packet.
    private(set) var keyboardKind: KeyboardKind?

    /// The visual keymap built exclusively from the downloaded firmware matrix.
    private(set) var keymapDefinition: KeymapDefinition?

    /// The current QMK layer-state mask.
    private(set) var layerStateMask: UInt32 = 1

    /// The current QMK default-layer-state mask.
    private(set) var defaultLayerStateMask: UInt32 = 1

    /// The latest firmware packet sequence, useful for future diagnostics.
    private(set) var latestSequence: UInt32 = 0

    /// The capabilities advertised by the connected firmware.
    private(set) var capabilities: UInt32 = 0

    /// The delayed state that determines whether the layer HUD is visible.
    let layerHUD: LayerHUDModel

    /// The editable base-layer RGB Matrix configuration.
    var rgbSettings: RGBSettings = .default {
        didSet {
            scheduleRGBSettingsUpdate()
        }
    }

    /// The long-lived HID monitor that outlives every app window.
    @ObservationIgnored private let monitor: KeyboardHIDMonitor

    /// A pending debounce that coalesces native color-picker changes.
    @ObservationIgnored private var pendingRGBUpdate: Task<Void, Never>?

    /// The most recent configuration sent but not yet echoed by firmware.
    @ObservationIgnored private var rgbSettingsAwaitingAcknowledgement: RGBSettings?

    /// Prevents keyboard-originated state from being written back to the keyboard.
    @ObservationIgnored private var isApplyingKeyboardRGBSettings = false

    /// Creates app state and immediately begins monitoring on the main run loop.
    /// - Parameters:
    ///   - monitor: The HID monitor to retain for the application's lifetime.
    ///   - layerHUD: The delayed HUD state to retain for the application's lifetime.
    init(
        monitor: KeyboardHIDMonitor = KeyboardHIDMonitor(),
        layerHUD: LayerHUDModel = LayerHUDModel()
    ) {
        self.monitor = monitor
        self.layerHUD = layerHUD
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

    /// Whether the active firmware supports explicit RGB Matrix settings.
    var supportsRGBSettings: Bool {
        connectionStatus.isConnected
            && capabilities & KeymapProtocol.rgbSettingsCapability != 0
    }

    /// Restarts discovery and downloads fresh keymap and state data from matching devices.
    func reconnect() {
        cancelRGBSettingsUpdate()
        layerHUD.hideImmediately()
        connectionStatus = .searching
        keyboardKind = nil
        keymapDefinition = nil
        monitor.restart()
    }

    /// Coalesces rapid native color-picker changes before persisting them to QMK.
    private func scheduleRGBSettingsUpdate() {
        guard !isApplyingKeyboardRGBSettings, supportsRGBSettings else { return }

        pendingRGBUpdate?.cancel()
        let settings = rgbSettings
        pendingRGBUpdate = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(150))
            } catch {
                return
            }
            guard let self,
                  !Task.isCancelled,
                  self.rgbSettings == settings else { return }
            self.pendingRGBUpdate = nil
            self.rgbSettingsAwaitingAcknowledgement = settings
            self.monitor.applyRGBSettings(settings)
        }
    }

    /// Cancels pending RGB transport work when the active device changes.
    private func cancelRGBSettingsUpdate() {
        pendingRGBUpdate?.cancel()
        pendingRGBUpdate = nil
        rgbSettingsAwaitingAcknowledgement = nil
    }

    /// Applies firmware RGB state without scheduling a host write-back.
    /// - Parameter settings: The validated configuration reported by QMK.
    private func applyKeyboardRGBSettings(_ settings: RGBSettings) {
        isApplyingKeyboardRGBSettings = true
        rgbSettings = settings
        isApplyingKeyboardRGBSettings = false
    }

    /// Applies a device-monitor event to observable UI state.
    /// - Parameter event: The event emitted by the monitor.
    private func receive(_ event: KeyboardMonitorEvent) {
        switch event {
        case .searching:
            cancelRGBSettingsUpdate()
            layerHUD.hideImmediately()
            connectionStatus = .searching
            keyboardKind = nil
            keymapDefinition = nil
        case let .keymap(firmwareKeymap):
            layerHUD.hideImmediately()
            guard let definition = KeymapDefinition(firmwareKeymap: firmwareKeymap) else {
                connectionStatus = .failed("Firmware matrix does not match the supported keyboard geometry.")
                return
            }
            keyboardKind = firmwareKeymap.keyboardKind
            keymapDefinition = definition
        case let .state(report):
            guard keymapDefinition?.keyboardKind == report.keyboardKind else { return }
            keyboardKind = report.keyboardKind
            layerStateMask = report.layerStateMask
            defaultLayerStateMask = report.defaultLayerStateMask
            latestSequence = report.sequence
            capabilities = report.capabilities
            connectionStatus = .connected
            layerHUD.update(
                activeLayer: activeLayer,
                activeLayerMask: effectiveLayerMask
            )
            if pendingRGBUpdate == nil,
               let reportedSettings = report.rgbSettings,
               rgbSettingsAwaitingAcknowledgement == nil
                || rgbSettingsAwaitingAcknowledgement == reportedSettings {
                rgbSettingsAwaitingAcknowledgement = nil
                applyKeyboardRGBSettings(reportedSettings)
            }
        case .disconnected:
            cancelRGBSettingsUpdate()
            layerHUD.hideImmediately()
            connectionStatus = .disconnected
        case let .failed(message):
            cancelRGBSettingsUpdate()
            layerHUD.hideImmediately()
            connectionStatus = .failed(message)
        }
    }

#if DEBUG
    /// Creates deterministic app state for previews without opening the HID manager.
    /// - Parameters:
    ///   - connectionStatus: The connection phase to render.
    ///   - keyboardKind: The keyboard model to render, or `nil` for the waiting state.
    ///   - activeLayers: Nondefault layers whose bits should be active.
    ///   - rgbSettings: The base-layer RGB configuration to render.
    /// - Returns: A preview-only model that performs no device discovery.
    static func preview(
        connectionStatus: ConnectionStatus = .connected,
        keyboardKind: KeyboardKind? = .elora,
        activeLayers: [KeymapLayer] = [],
        rgbSettings: RGBSettings = .default
    ) -> AppModel {
        AppModel(
            previewConnectionStatus: connectionStatus,
            keyboardKind: keyboardKind,
            activeLayers: activeLayers,
            rgbSettings: rgbSettings
        )
    }

    /// Creates preview state while deliberately leaving its HID monitor stopped.
    /// - Parameters:
    ///   - previewConnectionStatus: The connection phase to render.
    ///   - keyboardKind: The keyboard model to render.
    ///   - activeLayers: Nondefault layers whose bits should be active.
    ///   - rgbSettings: The base-layer RGB configuration to render.
    private init(
        previewConnectionStatus: ConnectionStatus,
        keyboardKind: KeyboardKind?,
        activeLayers: [KeymapLayer],
        rgbSettings: RGBSettings
    ) {
        monitor = KeyboardHIDMonitor()
        layerHUD = LayerHUDModel()
        connectionStatus = previewConnectionStatus
        self.keyboardKind = keyboardKind
        keymapDefinition = keyboardKind.map { KeymapDefinition.preview(for: $0) }
        layerStateMask = activeLayers.reduce(into: UInt32.zero) { mask, layer in
            mask |= UInt32(1) << UInt32(layer.rawValue)
        }
        defaultLayerStateMask = UInt32(1) << UInt32(KeymapLayer.base.rawValue)
        capabilities = previewConnectionStatus.isConnected ? 7 : 0
        self.rgbSettings = rgbSettings
    }
#endif
}
