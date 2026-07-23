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
    /// The current hardware discovery or connection state.
    public private(set) var connectionStatus: ConnectionStatus = .searching

    /// The connected keyboard model, when known.
    public private(set) var layoutID: LayoutID?

    /// The renderer input downloaded from the connected keyboard.
    public private(set) var keymapDefinition: KeymapDefinition?

    /// The momentary firmware layer-state bit mask.
    public private(set) var layerStateMask: UInt32 = 1

    /// The persistent firmware default-layer bit mask.
    public private(set) var defaultLayerStateMask: UInt32 = 1

    /// The sequence number of the latest accepted state report.
    public private(set) var latestSequence: UInt32 = 0

    /// The capability bit mask advertised by firmware.
    public private(set) var capabilities: UInt32 = 0

    /// The editable base-layer RGB Matrix configuration.
    public var rgbSettings: RGBSettings = .default {
        didSet {
            guard rgbSettings != oldValue else { return }
            state.setRGBSettings(rgbSettings)
            scheduleRGBSettingsUpdate()
        }
    }

    /// Trigger-driven HUD state consumed by each platform's native overlay controller.
    public let layerHUD: LayerHUDModel

    /// The injected platform hardware implementation.
    @ObservationIgnored @Dependency(\.keyboardHardware) private var hardware

    /// Canonical reducer state kept outside Observation tracking.
    @ObservationIgnored private var state = CompanionState()

    /// The delayed and coalesced RGB write currently pending.
    @ObservationIgnored private var pendingRGBUpdate: Task<Void, Never>?

    /// The RGB settings waiting for firmware acknowledgement.
    @ObservationIgnored private var rgbSettingsAwaitingAcknowledgement: RGBSettings?

    /// Whether firmware state is currently being copied into ``rgbSettings``.
    @ObservationIgnored private var isApplyingKeyboardRGBSettings = false

    /// Creates the shared model and starts the currently injected hardware client.
    ///
    /// - Parameter layerHUD: The layer HUD state machine.
    private init(layerHUD: LayerHUDModel) {
        self.layerHUD = layerHUD
        hardware.setEventHandler { [weak self] event in
            self?.receive(event)
        }
        hardware.start()
    }

    /// Creates a live model with a platform hardware implementation.
    ///
    /// - Parameters:
    ///   - hardware: The platform hardware implementation to inject.
    ///   - layerHUD: The layer HUD state machine.
    /// - Returns: A model that has started hardware discovery.
    public static func makeLive(
        hardware: any KeyboardHardwareClient,
        layerHUD: LayerHUDModel = LayerHUDModel()
    ) -> KeymapCompanionModel {
        withDependencies {
            $0.keyboardHardware = hardware
        } operation: {
            KeymapCompanionModel(layerHUD: layerHUD)
        }
    }

    /// Creates a model from deterministic state without starting hardware access.
    ///
    /// - Parameters:
    ///   - state: The canonical reducer state.
    ///   - layerHUD: The layer HUD state machine.
    private init(state: CompanionState, layerHUD: LayerHUDModel) {
        self.state = state
        self.layerHUD = layerHUD
        synchronizeObservableState()
    }

    /// The union of momentary and default firmware layer masks.
    public var effectiveLayerMask: UInt32 {
        layerStateMask | defaultLayerStateMask
    }

    /// The highest layer in ``effectiveLayerMask``.
    public var activeLayer: KeymapLayer {
        keymapDefinition?.highestActiveLayer(in: effectiveLayerMask) ?? .base
    }

    /// Whether the connected firmware accepts explicit RGB settings.
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
    ///
    /// - Parameter update: A mutation to apply to a copy of the current settings.
    public func updateRGBSettings(_ update: (_ settings: inout RGBSettings) -> Void) {
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

    /// Schedules a coalesced RGB write after the editing delay.
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
                self.rgbSettings == settings
            else { return }
            self.pendingRGBUpdate = nil
            self.rgbSettingsAwaitingAcknowledgement = settings
            self.hardware.applyRGBSettings(settings)
        }
    }

    /// Cancels pending RGB work and acknowledgement tracking.
    private func cancelRGBSettingsUpdate() {
        pendingRGBUpdate?.cancel()
        pendingRGBUpdate = nil
        rgbSettingsAwaitingAcknowledgement = nil
    }

    /// Reduces one hardware event into observable model state.
    ///
    /// - Parameter event: The event emitted by the platform hardware implementation.
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
            guard keymapDefinition?.layoutID == report.layoutID else { return }
            let acceptsRGBSettings =
                pendingRGBUpdate == nil
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

        case let .layerHUDTrigger(trigger):
            keymapMayHaveChanged = false
            guard keymapDefinition?.layoutID == trigger.layoutID,
                state.layoutID == trigger.layoutID,
                state.layerStateMask == trigger.layerStateMask,
                state.defaultLayerStateMask == trigger.defaultLayerStateMask
            else {
                return
            }
            let activeLayer = keymapDefinition?.highestActiveLayer(
                in: trigger.effectiveLayerMask
            ) ?? .base
            guard activeLayer.isHUDLayer else { return }
            layerHUD.present(
                activeLayer: activeLayer,
                activeLayerMask: trigger.effectiveLayerMask
            )
        }
        synchronizeObservableState(includeKeymapDefinition: keymapMayHaveChanged)
    }

    /// Copies reduced state into independently observable properties.
    ///
    /// This prevents sequence-only HID reports from invalidating unrelated UI.
    ///
    /// - Parameter includeKeymapDefinition: Whether to compare and copy renderer input.
    private func synchronizeObservableState(includeKeymapDefinition: Bool = true) {
        if connectionStatus != state.connectionStatus {
            connectionStatus = state.connectionStatus
        }
        if layoutID != state.layoutID {
            layoutID = state.layoutID
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
    /// Preview factories for the shared companion state model.
    public extension KeymapCompanionModel {
        /// Creates deterministic preview state without starting a hardware client.
        ///
        /// - Parameters:
        ///   - connectionStatus: The simulated hardware connection state.
        ///   - layoutID: The simulated keyboard layout.
        ///   - activeLayers: The simulated momentary active layers.
        ///   - rgbSettings: The simulated RGB Matrix settings.
        /// - Returns: A deterministic model for previews and tests.
        static func makePreview(
            connectionStatus: ConnectionStatus = .connected,
            layoutID: LayoutID? = .elora,
            activeLayers: [KeymapLayer] = [],
            rgbSettings: RGBSettings = .default
        ) -> KeymapCompanionModel {
            let layerStateMask = activeLayers.reduce(into: UInt32.zero) { mask, layer in
                mask |= UInt32(1) << UInt32(layer.rawValue)
            }
            return KeymapCompanionModel(
                state: CompanionState(
                    connectionStatus: connectionStatus,
                    layoutID: layoutID,
                    keymapDefinition: layoutID.map { KeymapDefinition.makePreview(for: $0) },
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
