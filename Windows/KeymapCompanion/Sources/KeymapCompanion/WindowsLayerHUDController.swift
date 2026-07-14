import CWindowsShell
import Foundation
import KeymapCompanionCore
import UWP
import WinAppSDK
import WinUI

/// A delayed, always-on-top, click-through WinUI layer overlay. It remains a
/// Windows-only presentation surface while consuming the shared renderer model.
final class WindowsLayerHUDController: @unchecked Sendable {
    private static let windowTitle = "Keymap Companion — Layer HUD"

    private var window: Window?
    private var presentation: LayerHUDPresentation?
    private var definition: KeymapDefinition?
    private var mainWindowIsActive = true

    func update(
        definition: KeymapDefinition?,
        presentation: LayerHUDPresentation?,
        mainWindowIsVisible: Bool
    ) {
        self.definition = definition
        self.presentation = presentation
        mainWindowIsActive = mainWindowIsVisible
        renderIfVisible()
    }

    func mainWindowActivityDidChange(isActive: Bool) {
        mainWindowIsActive = isActive
        renderIfVisible()
    }

    func hideImmediately() {
        presentation = nil
        try? window?.appWindow.hide()
    }

    func close() throws {
        try window?.close()
        window = nil
    }

    private func renderIfVisible() {
        guard !mainWindowIsActive,
              let definition,
              let presentation else {
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

    private func makeContent(
        definition: KeymapDefinition,
        presentation: LayerHUDPresentation
    ) -> UIElement {
        let stack = StackPanel()
        stack.requestedTheme = .dark
        stack.orientation = .vertical
        stack.spacing = 10
        stack.padding = Thickness(left: 20, top: 16, right: 20, bottom: 16)
        stack.background = WindowsTheme.brush(25, 27, 34, alpha: 238)

        let heading = WindowsTheme.text("\(presentation.layer.displayName) layer", size: 20)
        heading.fontWeight = FontWeights.semiBold
        stack.children.append(heading)
        stack.children.append(WindowsKeymapRenderer.make(
            definition: definition,
            activeLayerMask: presentation.activeLayerMask,
            scale: 0.72
        ))
        return stack
    }
}
