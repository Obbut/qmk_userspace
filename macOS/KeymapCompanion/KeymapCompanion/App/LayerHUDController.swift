import AppKit
import Observation
import SwiftUI

/// Owns the process-lifetime nonactivating panel used for the layer HUD.
@MainActor
final class LayerHUDController: NSObject {
    /// Shared app state supplying the downloaded keymap and delayed HUD snapshot.
    private let model: AppModel

    /// The lazily created overlay panel.
    private var panel: LayerHUDPanel?

    /// A pending order-out operation used after the fade animation.
    private var fadeTask: Task<Void, Never>?

    /// Creates a controller and starts observing delayed HUD visibility.
    /// - Parameter model: The process-lifetime application state.
    init(model: AppModel) {
        self.model = model
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyWindowDidChange(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyWindowDidChange(_:)),
            name: NSWindow.didResignKeyNotification,
            object: nil
        )
        observePresentation()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Whether the app's normal main window currently owns keyboard focus.
    private var isMainWindowActive: Bool {
        guard let keyWindow = NSApplication.shared.keyWindow else { return false }
        return !(keyWindow is NSPanel)
            && keyWindow.level == .normal
            && keyWindow.canBecomeMain
    }

    /// Whether valid layer content should currently be shown in the overlay.
    private var shouldShowPanel: Bool {
        !isMainWindowActive
            && model.layerHUD.presentation != nil
            && model.keymapDefinition != nil
    }

    /// Installs one-shot Observation tracking for the next presentation change.
    private func observePresentation() {
        withObservationTracking {
            _ = model.layerHUD.presentation
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.presentationDidChange()
            }
        }
    }

    /// Applies the newest snapshot to AppKit and reinstalls Observation tracking.
    private func presentationDidChange() {
        updatePanelVisibility()
        observePresentation()
    }

    /// Responds immediately when the main app window gains or loses focus.
    /// - Parameter notification: The AppKit key-window notification.
    @objc private func keyWindowDidChange(_ notification: Notification) {
        updatePanelVisibility()
    }

    /// Reconciles panel visibility with both layer state and main-window focus.
    private func updatePanelVisibility() {
        if !isMainWindowActive,
           let presentation = model.layerHUD.presentation,
           let definition = model.keymapDefinition {
            show(definition: definition, presentation: presentation)
        } else {
            hide()
        }
    }

    /// Shows or refreshes the glass card without activating the application.
    /// - Parameters:
    ///   - definition: The downloaded keymap to render.
    ///   - presentation: The momentary-layer snapshot to display.
    private func show(
        definition: KeymapDefinition,
        presentation: LayerHUDPresentation
    ) {
        fadeTask?.cancel()
        fadeTask = nil

        let rootView = LayerHUDView(
            definition: definition,
            presentation: presentation
        )
        let panel: LayerHUDPanel
        if let existingPanel = self.panel {
            panel = existingPanel
            if let hostingView = panel.contentView as? NSHostingView<LayerHUDView> {
                hostingView.rootView = rootView
            } else {
                panel.contentView = NSHostingView(rootView: rootView)
            }
        } else {
            panel = makePanel(rootView: rootView)
            self.panel = panel
        }

        position(panel)
        let wasVisible = panel.isVisible
        if !wasVisible {
            panel.alphaValue = 0
            panel.orderFrontRegardless()
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = wasVisible ? 0.05 : 0.1
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }

    /// Fades the current card out while retaining its last valid keymap content.
    private func hide() {
        fadeTask?.cancel()
        fadeTask = nil
        guard let panel, panel.isVisible else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.08
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }

        fadeTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(80))
            } catch {
                return
            }

            guard let self, !self.shouldShowPanel else { return }
            self.panel?.orderOut(nil)
            self.panel?.alphaValue = 1
            self.fadeTask = nil
        }
    }

    /// Builds an AppKit HUD panel instead of a normal SwiftUI window scene.
    /// - Parameter rootView: The initial SwiftUI keymap card.
    /// - Returns: A transparent, click-through panel that never becomes key.
    private func makePanel(rootView: LayerHUDView) -> LayerHUDPanel {
        let panel = LayerHUDPanel(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 420),
            styleMask: [.nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: true
        )
        panel.contentView = NSHostingView(rootView: rootView)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .canJoinAllApplications,
            .transient,
            .ignoresCycle,
            .fullScreenAuxiliary,
            .fullScreenDisallowsTiling
        ]
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.worksWhenModal = true
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.isExcludedFromWindowsMenu = true
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        return panel
    }

    /// Places the HUD near the top-right corner of the screen containing the pointer.
    /// - Parameter panel: The overlay panel to size and position.
    private func position(_ panel: NSPanel) {
        guard let screen = NSScreen.screens.first(where: {
            $0.frame.contains(NSEvent.mouseLocation)
        }) ?? NSScreen.main else { return }

        let visibleFrame = screen.visibleFrame
        let edgeInset: CGFloat = 10
        let width = min(900, max(1, visibleFrame.width - edgeInset * 2))
        let height = min(420, max(1, visibleFrame.height - edgeInset * 2))
        let origin = NSPoint(
            x: visibleFrame.maxX - width - edgeInset,
            y: visibleFrame.maxY - height - edgeInset
        )
        panel.setFrame(NSRect(origin: origin, size: NSSize(width: width, height: height)), display: true)
    }
}

/// A click-through heads-up display panel that cannot take keyboard focus.
fileprivate final class LayerHUDPanel: NSPanel {
    /// Prevents the overlay from taking key-window status.
    override var canBecomeKey: Bool { false }

    /// Prevents the overlay from becoming the application's main window.
    override var canBecomeMain: Bool { false }
}
