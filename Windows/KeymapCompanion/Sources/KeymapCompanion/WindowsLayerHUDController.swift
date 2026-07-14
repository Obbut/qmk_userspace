import CWindowsShell
import Foundation
import KeymapCompanionCore
import UWP
import WinAppSDK
import WinUI

/// A delayed, always-on-top, click-through WinUI layer overlay.
///
/// This Windows-only presentation surface consumes the shared renderer model.
@MainActor
final class WindowsLayerHUDController {
    /// The native title used to locate and configure the overlay window.
    private static let windowTitle = "Keymap Companion — Layer HUD"

    /// The lazily created overlay window.
    private var window: Window?

    /// The delayed layer snapshot currently eligible for presentation.
    private var presentation: LayerHUDPresentation?

    /// The downloaded renderer input.
    private var definition: KeymapDefinition?

    /// Whether the primary app window currently has keyboard focus.
    private var mainWindowIsActive = true

    /// Updates renderer input and delayed layer presentation.
    ///
    /// - Parameters:
    ///   - definition: The downloaded renderer input.
    ///   - presentation: The delayed layer snapshot.
    ///   - mainWindowIsActive: Whether the primary window currently has keyboard focus.
    func update(
        definition: KeymapDefinition?,
        presentation: LayerHUDPresentation?,
        mainWindowIsActive: Bool
    ) {
        self.definition = definition
        self.presentation = presentation
        self.mainWindowIsActive = mainWindowIsActive
        renderIfVisible()
    }

    /// Reconciles overlay visibility after primary-window activity changes.
    ///
    /// - Parameter isActive: Whether the primary window currently has keyboard focus.
    func mainWindowActivityDidChange(isActive: Bool) {
        mainWindowIsActive = isActive
        renderIfVisible()
    }

    /// Hides the overlay and discards its delayed presentation.
    func hideImmediately() {
        presentation = nil
        try? window?.appWindow.hide()
    }

    /// Closes and releases the native overlay window.
    ///
    /// - Throws: A Swift/WinRT error when the window cannot close.
    func close() throws {
        try window?.close()
        window = nil
    }

    /// Reconciles native overlay visibility with current presentation state.
    private func renderIfVisible() {
        guard !mainWindowIsActive,
            let definition,
            let presentation
        else {
            try? window?.appWindow.hide()
            return
        }

        let window = ensureWindow()
        window.content = makeContent(definition: definition, presentation: presentation)
        try? window.appWindow.show(false)
        Self.windowTitle.withCString(encodedAs: UTF16.self) { title in
            _ = keymap_prepare_overlay_window(title)
        }
    }

    /// Returns the existing overlay window or creates and activates one.
    ///
    /// - Returns: The process-lifetime overlay window.
    private func ensureWindow() -> Window {
        if let window { return window }

        let window = Window()
        window.title = Self.windowTitle
        window.appWindow.isShownInSwitchers = false
        if let presenter = try? OverlappedPresenter.create() {
            presenter.isAlwaysOnTop = true
            presenter.isMaximizable = false
            presenter.isMinimizable = false
            presenter.isResizable = false
            try? presenter.setBorderAndTitleBar(false, false)
            try? window.appWindow.setPresenter(presenter)
        }
        try? window.appWindow.resize(SizeInt32(width: 900, height: 420))
        try? window.activate()
        Self.windowTitle.withCString(encodedAs: UTF16.self) { title in
            _ = keymap_prepare_overlay_window(title)
        }
        self.window = window
        return window
    }

    /// Creates the current layer overlay content.
    ///
    /// - Parameters:
    ///   - definition: The downloaded renderer input.
    ///   - presentation: The delayed layer snapshot.
    /// - Returns: The configured overlay content.
    private func makeContent(
        definition: KeymapDefinition,
        presentation: LayerHUDPresentation
    ) -> UIElement {
        let stack = StackPanel()
        stack.requestedTheme = .dark
        stack.orientation = .vertical
        stack.spacing = 10
        stack.padding = Thickness(left: 20, top: 16, right: 20, bottom: 16)
        stack.background = WindowsTheme.makeBrush(red: 25, green: 27, blue: 34, alpha: 238)

        let heading = WindowsTheme.makeText(text: "\(presentation.layer.displayName) layer", size: 20)
        heading.fontWeight = FontWeights.semiBold
        stack.children.append(heading)
        stack.children.append(
            WindowsKeymapSurface(
                definition: definition,
                activeLayerMask: presentation.activeLayerMask,
                scale: 0.72
            ).canvas)
        return stack
    }
}
