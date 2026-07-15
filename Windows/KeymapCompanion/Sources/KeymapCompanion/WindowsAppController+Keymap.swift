import KeymapCompanionCore
import UWP
import WinUI

/// Keymap and active-layer presentation for the Windows app controller.
extension WindowsAppController {
    /// Creates the downloaded keyboard card.
    ///
    /// - Parameter definition: The renderer input to present.
    /// - Returns: The configured keyboard card.
    func makeKeyboardCard(definition: KeymapDefinition) -> Border {
        let content = StackPanel()
        content.orientation = .vertical
        content.spacing = 16

        let name = WindowsTheme.makeText(text: definition.displayName, size: 21)
        name.fontWeight = FontWeights.semiBold
        content.children.append(name)
        content.children.append(makeLayerStrip(supportedLayers: definition.supportedLayers))

        let boardScroll = ScrollViewer()
        boardScroll.horizontalScrollBarVisibility = .auto
        boardScroll.verticalScrollBarVisibility = .disabled
        let surface = WindowsKeymapSurface(
            definition: definition,
            activeLayerMask: model.effectiveLayerMask
        )
        keymapSurface = surface
        boardScroll.content = surface.canvas
        content.children.append(boardScroll)
        return WindowsTheme.makeCard(content: content, padding: 22)
    }

    /// Creates the pills that summarize the active firmware layers.
    ///
    /// - Parameter supportedLayers: The layers supplied by the connected firmware.
    /// - Returns: The configured layer strip.
    private func makeLayerStrip(supportedLayers: [KeymapLayer]) -> StackPanel {
        let strip = StackPanel()
        strip.orientation = .horizontal
        strip.spacing = 8
        for layer in supportedLayers {
            let isActive = layer.isActive(inLayerMask: model.effectiveLayerMask)
            let pill = Border()
            pill.cornerRadius = WindowsTheme.makeCornerRadius(all: 10)
            pill.padding = Thickness(left: 10, top: 4, right: 10, bottom: 4)
            pill.background =
                isActive
                ? WindowsTheme.makeBrush(red: 73, green: 105, blue: 184, alpha: 210)
                : WindowsTheme.makeBrush(red: 255, green: 255, blue: 255, alpha: 14)
            let label = WindowsTheme.makeText(
                text:
                    layer.displayName,
                size: 12,
                color: isActive
                    ? WindowsTheme.makeColor(red: 255, green: 255, blue: 255)
                    : WindowsTheme.makeColor(red: 157, green: 164, blue: 181)
            )
            label.fontWeight = isActive ? FontWeights.semiBold : FontWeights.normal
            pill.child = label
            strip.children.append(pill)
            layerPillBorders.append(pill)
            layerPillLabels.append(label)
        }
        return strip
    }

    /// Synchronizes existing layer pills with a new effective layer mask.
    ///
    /// - Parameter activeLayerMask: The bit mask of active and default layers.
    func synchronizeLayerPills(activeLayerMask: UInt32) {
        guard let layers = model.keymapDefinition?.supportedLayers else { return }
        for (index, layer) in layers.enumerated() {
            guard index < layerPillBorders.count, index < layerPillLabels.count else { break }
            let isActive = layer.isActive(inLayerMask: activeLayerMask)
            layerPillBorders[index].background =
                isActive
                ? WindowsTheme.makeBrush(red: 73, green: 105, blue: 184, alpha: 210)
                : WindowsTheme.makeBrush(red: 255, green: 255, blue: 255, alpha: 14)
            layerPillLabels[index].foreground = SolidColorBrush(
                isActive
                    ? WindowsTheme.makeColor(red: 255, green: 255, blue: 255)
                    : WindowsTheme.makeColor(red: 157, green: 164, blue: 181)
            )
            layerPillLabels[index].fontWeight = isActive ? FontWeights.semiBold : FontWeights.normal
        }
    }
}
