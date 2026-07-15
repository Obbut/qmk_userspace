import CWindowsShell
import Dispatch
import KeymapCompanionCore
import Observation
import UWP
import WinAppSDK
import WinUI

/// The main-actor owner of native Windows presentation and shared app state.
@MainActor
final class WindowsAppController {
    /// The app's primary WinUI window.
    private let window = Window()

    /// The shared observable source of truth.
    let model: KeymapCompanionModel

    /// The native transient layer HUD.
    private lazy var hud = WindowsLayerHUDController()

    /// The native notification-area icon handle.
    private var tray: OpaquePointer?

    /// The model snapshot represented by the current visual tree.
    private var renderedSnapshot: WindowsViewSnapshot?

    /// The incrementally updated keyboard surface.
    var keymapSurface: WindowsKeymapSurface?

    /// The visible layer-pill borders ordered by firmware layer index.
    var layerPillBorders: [Border] = []

    /// The visible layer-pill labels ordered by firmware layer index.
    var layerPillLabels: [TextBlock] = []

    /// Whether process shutdown has started.
    private var isExiting = false

    /// Whether the primary window currently has keyboard focus.
    private var isMainWindowActive = true

    /// The strongly retained lighting enabled projection while its flyout exists.
    var rgbEnabledControl: ToggleSwitch?

    /// The strongly retained lighting effect projection while its flyout exists.
    var rgbEffectControl: ComboBox?

    /// The strongly retained lighting color-swatch projection while its flyout exists.
    var rgbSwatch: Border?

    /// The strongly retained lighting flyout projection while attached to the header button.
    var rgbFlyout: Flyout?

    /// The strongly retained brightness-label projection while its flyout exists.
    var brightnessLabel: TextBlock?

    /// The strongly retained brightness-fill projection while its flyout exists.
    var brightnessFill: Border?

    /// The strongly retained brightness-decrement projection while its flyout exists.
    var brightnessMinus: Button?

    /// The strongly retained brightness-increment projection while its flyout exists.
    var brightnessPlus: Button?

    /// The strongly retained animation-speed-label projection while its flyout exists.
    var speedLabel: TextBlock?

    /// The strongly retained animation-speed-fill projection while its flyout exists.
    var speedFill: Border?

    /// The strongly retained animation-speed-decrement projection while its flyout exists.
    var speedMinus: Button?

    /// The strongly retained animation-speed-increment projection while its flyout exists.
    var speedPlus: Button?

    /// Creates native Windows state around the shared observable model.
    init() {
        let hardware = WindowsKeyboardHardwareClient()
        model = KeymapCompanionModel.makeLive(hardware: hardware)
    }

    /// Builds, observes, and activates the primary window and tray icon.
    func launch() {
        window.title = "Keymap Companion"
        try? window.appWindow.setIcon(
            WinAppSDK.IconId(value: UInt64(KEYMAP_COMPANION_ICON))
        )
        try? window.appWindow.resize(SizeInt32(width: 1200, height: 780))
        window.content = makeContent()
        renderedSnapshot = WindowsViewSnapshot(model: model)
        observeModel()
        window.appWindow.closing.addHandler { [weak self] _, args in
            guard let self, !self.isExiting else { return }
            args?.cancel = true
            try? self.window.appWindow.hide()
        }
        window.activated.addHandler { [weak self] _, args in
            guard let self, let args else { return }
            self.isMainWindowActive = args.windowActivationState != .deactivated
            self.hud.mainWindowActivityDidChange(isActive: self.isMainWindowActive)
        }
        try? window.activate()
        tray = keymap_tray_create(
            { command, context in
                guard let context else { return }
                let controller = Unmanaged<WindowsAppController>
                    .fromOpaque(context)
                    .takeUnretainedValue()
                DispatchQueue.main.async {
                    controller.performTrayCommand(command)
                }
            },
            Unmanaged.passUnretained(self).toOpaque()
        )
        synchronizeTrayPresentation()
    }

    /// Stops shared hardware work and releases Windows presentation resources.
    func shutdown() {
        model.shutdown()
        hud.hideImmediately()
        if let tray {
            keymap_tray_destroy(tray)
            self.tray = nil
        }
    }

    /// Performs a command selected from the notification-area menu.
    ///
    /// - Parameter command: The native tray command identifier.
    private func performTrayCommand(_ command: UInt32) {
        switch command {
        case UInt32(KEYMAP_TRAY_OPEN):
            try? window.appWindow.show(true)
        case UInt32(KEYMAP_TRAY_RECONNECT):
            model.reconnect()
        case UInt32(KEYMAP_TRAY_EXIT):
            isExiting = true
            shutdown()
            try? hud.close()
            try? window.close()
            keymap_quit_application()
        default:
            break
        }
    }

    /// Re-arms one-shot Swift Observation tracking after every model change.
    private func observeModel() {
        withObservationTracking {
            _ = model.connectionStatus
            _ = model.layoutID
            _ = model.keymapDefinition
            _ = model.layerStateMask
            _ = model.defaultLayerStateMask
            _ = model.capabilities
            _ = model.rgbSettings
            _ = model.layerHUD.presentation
        } onChange: { [weak self] in
            DispatchQueue.main.async { [weak self] in
                guard let self, !self.isExiting else { return }
                self.modelDidChange()
                self.observeModel()
            }
        }
    }

    /// Applies the smallest visual update for the latest observable state.
    private func modelDidChange() {
        let current = WindowsViewSnapshot(model: model)
        let previous = renderedSnapshot ?? current
        renderedSnapshot = current
        renderChanges(from: previous, to: current)
        hud.update(
            definition: model.keymapDefinition,
            presentation: model.layerHUD.presentation,
            mainWindowIsActive: isMainWindowActive
        )
        synchronizeTrayPresentation()
    }

    /// Synchronizes the native tray icon, tooltip, and menu state with the shared model.
    private func synchronizeTrayPresentation() {
        guard let tray else { return }
        let connectionState =
            switch model.connectionStatus {
            case .searching:
                UInt32(KEYMAP_TRAY_CONNECTION_SEARCHING)
            case .connected:
                UInt32(KEYMAP_TRAY_CONNECTION_CONNECTED)
            case .disconnected:
                UInt32(KEYMAP_TRAY_CONNECTION_DISCONNECTED)
            case .failed:
                UInt32(KEYMAP_TRAY_CONNECTION_FAILED)
            }
        keymap_tray_update_state(
            tray,
            connectionState,
            model.layoutID?.rawValue ?? 0,
            UInt32(model.activeLayer.rawValue)
        )
    }

    /// Applies a lighting mutation through the shared model.
    ///
    /// - Parameter update: The mutation to apply to the current RGB settings.
    func updateRGBSettings(_ update: (_ settings: inout RGBSettings) -> Void) {
        model.updateRGBSettings(update)
    }

    /// Rebuilds the root content from the current model snapshot.
    ///
    /// - Returns: The root WinUI element.
    private func makeContent() -> UIElement {
        clearRGBControlReferences()
        keymapSurface = nil
        layerPillBorders.removeAll(keepingCapacity: true)
        layerPillLabels.removeAll(keepingCapacity: true)
        let body = StackPanel()
        body.orientation = .vertical
        body.spacing = 20
        body.margin = Thickness(left: 32, top: 28, right: 32, bottom: 36)
        body.requestedTheme = .dark

        body.children.append(makeHeader())
        if let connectionInfo = makeConnectionInfo() {
            body.children.append(connectionInfo)
        }

        if let definition = model.keymapDefinition {
            body.children.append(makeKeyboardCard(definition: definition))
        } else {
            body.children.append(makeEmptyState())
        }
        let scroll = ScrollViewer()
        scroll.background = WindowsTheme.makeBrush(red: 23, green: 25, blue: 32)
        scroll.verticalScrollBarVisibility = .auto
        scroll.horizontalScrollBarVisibility = .disabled
        scroll.content = body
        return scroll
    }

    /// Applies structural or incremental changes between two model snapshots.
    ///
    /// - Parameters:
    ///   - previous: The snapshot represented by the current visual tree.
    ///   - current: The latest shared-model snapshot.
    private func renderChanges(from previous: WindowsViewSnapshot, to current: WindowsViewSnapshot) {
        guard previous != current else { return }
        let structureChanged =
            previous.connectionStatus != current.connectionStatus
            || previous.layoutID != current.layoutID
            || previous.keymapDefinition != current.keymapDefinition
            || previous.supportsRGBSettings != current.supportsRGBSettings
        if structureChanged {
            renderAll()
            return
        }

        if previous.effectiveLayerMask != current.effectiveLayerMask,
            model.keymapDefinition != nil
        {
            keymapSurface?.update(activeLayerMask: current.effectiveLayerMask)
            synchronizeLayerPills(activeLayerMask: current.effectiveLayerMask)
        }
        if previous.rgbSettings != current.rgbSettings {
            synchronizeRGBControls()
        }
    }

    /// Replaces the visual tree after a structural model change.
    private func renderAll() {
        window.content = makeContent()
    }

    /// Releases projections for controls owned by the current lighting flyout.
    private func clearRGBControlReferences() {
        if rgbFlyout?.isOpen == true {
            try? rgbFlyout?.hide()
        }
        rgbFlyout = nil
        rgbEnabledControl = nil
        rgbEffectControl = nil
        rgbSwatch = nil
        brightnessLabel = nil
        brightnessFill = nil
        brightnessMinus = nil
        brightnessPlus = nil
        speedLabel = nil
        speedFill = nil
        speedMinus = nil
        speedPlus = nil
    }
}
