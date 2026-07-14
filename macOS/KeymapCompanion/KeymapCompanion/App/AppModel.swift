import Observation
import KeymapCompanionCore

/// Main-actor application state shared by the window and menu-bar scenes.
@MainActor
@Observable
final class AppModel {
    /// Platform-neutral state shared with the Windows companion.
    private var state = CompanionState()

    var connectionStatus: ConnectionStatus { state.connectionStatus }
    var keyboardKind: KeyboardKind? { state.keyboardKind }
    var keymapDefinition: KeymapDefinition? { state.keymapDefinition }
    var layerStateMask: UInt32 { state.layerStateMask }
    var defaultLayerStateMask: UInt32 { state.defaultLayerStateMask }
    var latestSequence: UInt32 { state.latestSequence }
    var capabilities: UInt32 { state.capabilities }

    /// The delayed state that determines whether the layer HUD is visible.
    let layerHUD: LayerHUDModel

    /// The editable base-layer RGB Matrix configuration.
    var rgbSettings: RGBSettings {
        get { state.rgbSettings }
        set {
            state.setRGBSettings(newValue)
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
        state.effectiveLayerMask
    }

    /// The highest layer currently visible to the user.
    var activeLayer: KeymapLayer {
        state.activeLayer
    }

    /// Whether the active firmware supports explicit RGB Matrix settings.
    var supportsRGBSettings: Bool {
        state.supportsRGBSettings
    }

    /// Restarts discovery and downloads fresh keymap and state data from matching devices.
    func reconnect() {
        cancelRGBSettingsUpdate()
        layerHUD.hideImmediately()
        state.apply(.searching)
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
        state.setRGBSettings(settings)
        isApplyingKeyboardRGBSettings = false
    }

    /// Applies a device-monitor event to observable UI state.
    /// - Parameter event: The event emitted by the monitor.
    private func receive(_ event: KeyboardMonitorEvent) {
        switch event {
        case .searching:
            cancelRGBSettingsUpdate()
            layerHUD.hideImmediately()
            state.apply(event)
        case .keymap:
            layerHUD.hideImmediately()
            state.apply(event)
        case let .state(report):
            guard keymapDefinition?.keyboardKind == report.keyboardKind else { return }
            let acceptsRGBSettings = pendingRGBUpdate == nil
                && report.rgbSettings != nil
                && (rgbSettingsAwaitingAcknowledgement == nil
                    || rgbSettingsAwaitingAcknowledgement == report.rgbSettings)
            state.apply(event, acceptRGBSettings: acceptsRGBSettings)
            layerHUD.update(
                activeLayer: activeLayer,
                activeLayerMask: effectiveLayerMask
            )
            if acceptsRGBSettings, let reportedSettings = report.rgbSettings {
                rgbSettingsAwaitingAcknowledgement = nil
                applyKeyboardRGBSettings(reportedSettings)
            }
        case .disconnected:
            cancelRGBSettingsUpdate()
            layerHUD.hideImmediately()
            state.apply(event)
        case .failed:
            cancelRGBSettingsUpdate()
            layerHUD.hideImmediately()
            state.apply(event)
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
        let layerStateMask = activeLayers.reduce(into: UInt32.zero) { mask, layer in
            mask |= UInt32(1) << UInt32(layer.rawValue)
        }
        state = CompanionState(
            connectionStatus: previewConnectionStatus,
            keyboardKind: keyboardKind,
            keymapDefinition: keyboardKind.map { KeymapDefinition.preview(for: $0) },
            layerStateMask: layerStateMask,
            defaultLayerStateMask: UInt32(1) << UInt32(KeymapLayer.base.rawValue),
            capabilities: previewConnectionStatus.isConnected ? 7 : 0,
            rgbSettings: rgbSettings
        )
    }
#endif
}
