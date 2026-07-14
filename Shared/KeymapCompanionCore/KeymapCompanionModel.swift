import Dependencies
import Observation

/// Shared observable source of truth for the native macOS and Windows apps.
///
/// Presentation remains platform-specific. This model owns application state,
/// RGB write coalescing, HUD state, and all interaction with the injected
/// hardware boundary.
@MainActor
@Observable
public final class KeymapCompanionModel {
    public private(set) var connectionStatus: ConnectionStatus = .searching
    public private(set) var keyboardKind: KeyboardKind?
    public private(set) var keymapDefinition: KeymapDefinition?
    public private(set) var layerStateMask: UInt32 = 1
    public private(set) var defaultLayerStateMask: UInt32 = 1
    public private(set) var latestSequence: UInt32 = 0
    public private(set) var capabilities: UInt32 = 0

    /// The editable base-layer RGB Matrix configuration.
    public var rgbSettings: RGBSettings = .default {
        didSet {
            guard rgbSettings != oldValue else { return }
            state.setRGBSettings(rgbSettings)
            scheduleRGBSettingsUpdate()
        }
    }

    /// Delayed HUD state consumed by each platform's native overlay controller.
    public let layerHUD: LayerHUDModel

    @ObservationIgnored @Dependency(\.keyboardHardware) private var hardware
    @ObservationIgnored private var state = CompanionState()
    @ObservationIgnored private var pendingRGBUpdate: Task<Void, Never>?
    @ObservationIgnored private var rgbSettingsAwaitingAcknowledgement: RGBSettings?
    @ObservationIgnored private var isApplyingKeyboardRGBSettings = false

    /// Creates the shared model and starts the injected platform hardware client.
    public init(layerHUD: LayerHUDModel = LayerHUDModel()) {
        self.layerHUD = layerHUD
        hardware.setEventHandler { [weak self] event in
            self?.receive(event)
        }
        hardware.start()
    }

    /// Creates a live model while capturing one platform implementation in the
    /// model's `@Dependency` storage.
    public static func live(
        hardware: any KeyboardHardwareClient,
        layerHUD: LayerHUDModel = LayerHUDModel()
    ) -> KeymapCompanionModel {
        withDependencies {
            $0.keyboardHardware = hardware
        } operation: {
            KeymapCompanionModel(layerHUD: layerHUD)
        }
    }

    private init(state: CompanionState, layerHUD: LayerHUDModel) {
        self.state = state
        self.layerHUD = layerHUD
        synchronizeObservableState()
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

    /// Restarts discovery and downloads fresh state from matching devices.
    public func reconnect() {
        cancelRGBSettingsUpdate()
        layerHUD.hideImmediately()
        state.apply(.searching)
        synchronizeObservableState()
        hardware.restart()
    }

    /// Updates lighting state while preserving the model's write coalescing.
    public func updateRGBSettings(_ update: (inout RGBSettings) -> Void) {
        guard supportsRGBSettings else { return }
        var settings = rgbSettings
        update(&settings)
        rgbSettings = settings
    }

    /// Stops hardware access and pending model work during app shutdown.
    public func shutdown() {
        cancelRGBSettingsUpdate()
        layerHUD.hideImmediately()
        hardware.stop()
    }

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
            self.hardware.applyRGBSettings(settings)
        }
    }

    private func cancelRGBSettingsUpdate() {
        pendingRGBUpdate?.cancel()
        pendingRGBUpdate = nil
        rgbSettingsAwaitingAcknowledgement = nil
    }

    private func receive(_ event: KeyboardMonitorEvent) {
        let keymapMayHaveChanged: Bool
        switch event {
        case .searching, .disconnected, .failed:
            keymapMayHaveChanged = true
            cancelRGBSettingsUpdate()
            layerHUD.hideImmediately()
            state.apply(event)

        case .keymap:
            keymapMayHaveChanged = true
            layerHUD.hideImmediately()
            state.apply(event)

        case let .state(report):
            keymapMayHaveChanged = false
            guard keymapDefinition?.keyboardKind == report.keyboardKind else { return }
            let acceptsRGBSettings = pendingRGBUpdate == nil
                && report.rgbSettings != nil
                && (rgbSettingsAwaitingAcknowledgement == nil
                    || rgbSettingsAwaitingAcknowledgement == report.rgbSettings)
            state.apply(event, acceptRGBSettings: acceptsRGBSettings)
            if acceptsRGBSettings {
                rgbSettingsAwaitingAcknowledgement = nil
            }
            layerHUD.update(
                activeLayer: state.activeLayer,
                activeLayerMask: state.effectiveLayerMask
            )
        }
        synchronizeObservableState(includeKeymapDefinition: keymapMayHaveChanged)
    }

    /// Copies reduced state into independently observable properties. This
    /// prevents sequence-only HID reports from invalidating unrelated UI.
    private func synchronizeObservableState(includeKeymapDefinition: Bool = true) {
        if connectionStatus != state.connectionStatus {
            connectionStatus = state.connectionStatus
        }
        if keyboardKind != state.keyboardKind {
            keyboardKind = state.keyboardKind
        }
        if includeKeymapDefinition, keymapDefinition != state.keymapDefinition {
            keymapDefinition = state.keymapDefinition
        }
        if layerStateMask != state.layerStateMask {
            layerStateMask = state.layerStateMask
        }
        if defaultLayerStateMask != state.defaultLayerStateMask {
            defaultLayerStateMask = state.defaultLayerStateMask
        }
        if latestSequence != state.latestSequence {
            latestSequence = state.latestSequence
        }
        if capabilities != state.capabilities {
            capabilities = state.capabilities
        }
        if rgbSettings != state.rgbSettings {
            isApplyingKeyboardRGBSettings = true
            rgbSettings = state.rgbSettings
            isApplyingKeyboardRGBSettings = false
        }
    }
}

#if DEBUG
public extension KeymapCompanionModel {
    /// Creates deterministic preview state without starting a hardware client.
    static func preview(
        connectionStatus: ConnectionStatus = .connected,
        keyboardKind: KeyboardKind? = .elora,
        activeLayers: [KeymapLayer] = [],
        rgbSettings: RGBSettings = .default
    ) -> KeymapCompanionModel {
        let layerStateMask = activeLayers.reduce(into: UInt32.zero) { mask, layer in
            mask |= UInt32(1) << UInt32(layer.rawValue)
        }
        return KeymapCompanionModel(
            state: CompanionState(
                connectionStatus: connectionStatus,
                keyboardKind: keyboardKind,
                keymapDefinition: keyboardKind.map { KeymapDefinition.preview(for: $0) },
                layerStateMask: layerStateMask,
                defaultLayerStateMask: UInt32(1) << UInt32(KeymapLayer.base.rawValue),
                capabilities: connectionStatus.isConnected ? 7 : 0,
                rgbSettings: rgbSettings
            ),
            layerHUD: LayerHUDModel()
        )
    }
}
#endif
