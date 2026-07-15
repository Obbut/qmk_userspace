import KeymapCompanionCore
import UWP
import WinUI

/// Header and connection guidance for the Windows app controller.
extension WindowsAppController {
    /// Creates the app identity and primary action row.
    ///
    /// - Returns: The configured header element.
    func makeHeader() -> UIElement {
        let header = Grid()
        header.columnSpacing = 18
        header.verticalAlignment = .center
        let flexibleColumn = ColumnDefinition()
        flexibleColumn.width = GridLength(value: 1, gridUnitType: .star)
        header.columnDefinitions.append(flexibleColumn)
        let actionsColumn = ColumnDefinition()
        actionsColumn.width = GridLength(value: 1, gridUnitType: .auto)
        header.columnDefinitions.append(actionsColumn)

        let title = WindowsTheme.makeText(text: "Keymap Companion", size: 30)
        title.fontWeight = FontWeights.semiBold
        title.verticalAlignment = .center
        header.children.append(title)

        let actions = StackPanel()
        actions.orientation = .horizontal
        actions.spacing = 10
        actions.verticalAlignment = .center
        actions.horizontalAlignment = .right
        if model.supportsRGBSettings {
            actions.children.append(makeLightingButton())
        }

        let reconnect = Button()
        reconnect.content = "Reconnect"
        reconnect.padding = Thickness(left: 16, top: 8, right: 16, bottom: 8)
        reconnect.click.addHandler { [weak self] _, _ in self?.model.reconnect() }
        try? AutomationProperties.setName(reconnect, "Reconnect keyboard")
        actions.children.append(reconnect)
        try? Grid.setColumn(actions, 1)
        header.children.append(actions)
        return header
    }

    /// Creates the button and flyout for keyboard lighting settings.
    ///
    /// - Returns: The configured lighting button.
    private func makeLightingButton() -> Button {
        let button = Button()
        button.content = "Lighting"
        button.padding = Thickness(left: 16, top: 8, right: 16, bottom: 8)
        try? AutomationProperties.setName(button, "Keyboard lighting settings")

        let flyout = Flyout()
        flyout.placement = .bottomEdgeAlignedRight
        flyout.content = makeRGBFlyoutContent()
        flyout.opening.addHandler { [weak self] _, _ in
            self?.synchronizeRGBControls()
        }
        rgbFlyout = flyout
        button.flyout = flyout
        return button
    }

    /// Creates connection guidance when live keyboard state is unavailable.
    ///
    /// - Returns: A configured information bar, or `nil` while connected.
    func makeConnectionInfo() -> InfoBar? {
        guard model.connectionStatus != .connected else { return nil }
        let info = InfoBar()
        info.isOpen = true
        info.isClosable = false
        info.isIconVisible = true
        switch model.connectionStatus {
        case .searching:
            info.severity = .informational
            info.title = "Looking for your keyboard"
            info.message = "Connect an Elora Rev2 or Kyria Rev4 running the companion protocol."
        case .connected:
            return nil
        case .disconnected:
            info.severity = .warning
            info.title = "Keyboard disconnected"
            info.message = "The last downloaded keymap remains visible. Reconnect the keyboard to resume live updates."
        case let .failed(message):
            info.severity = .error
            info.title = "Could not read the keyboard"
            info.message = message
        }
        return info
    }

    /// Creates the placeholder card shown before a keymap is available.
    ///
    /// - Returns: The configured placeholder card.
    func makeEmptyState() -> Border {
        let content = StackPanel()
        content.orientation = .vertical
        content.spacing = 8
        let title = WindowsTheme.makeText(text: "Your keymap will appear here", size: 21)
        title.fontWeight = FontWeights.semiBold
        content.children.append(title)
        content.children.append(
            WindowsTheme.makeText(
                text:
                    "Keymap Companion downloads the keymap compiled into QMK and verifies its fingerprint before drawing it.",
                size: 14,
                color: WindowsTheme.makeColor(red: 177, green: 184, blue: 201)
            )
        )
        let card = WindowsTheme.makeCard(content: content, padding: 28)
        card.minHeight = 190
        return card
    }
}
