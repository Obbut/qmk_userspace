import CWindowsShell
import KeymapCompanionCore
import UWP
import WinUI

/// RGB Matrix lighting presentation for the Windows app controller.
extension WindowsAppController {
    /// Creates the complete native lighting flyout.
    ///
    /// - Returns: The configured flyout content.
    func makeRGBFlyoutContent() -> UIElement {
        let content = StackPanel()
        content.orientation = .vertical
        content.spacing = 16
        content.width = 500
        content.margin = Thickness(left: 4, top: 4, right: 4, bottom: 4)

        let title = WindowsTheme.makeText(text: "Keyboard lighting", size: 21)
        title.fontWeight = FontWeights.semiBold
        content.children.append(title)
        content.children.append(
            WindowsTheme.makeText(
                text:
                    "Changes are saved directly to the connected keyboard.",
                size: 13,
                color: WindowsTheme.makeColor(red: 177, green: 184, blue: 201)
            )
        )

        let controls = StackPanel()
        controls.orientation = .horizontal
        controls.spacing = 18
        controls.verticalAlignment = .bottom

        let enabled = ToggleSwitch()
        enabled.header = "Lighting"
        enabled.onContent = "On"
        enabled.offContent = "Off"
        enabled.isOn = model.rgbSettings.isEnabled
        rgbEnabledControl = enabled
        enabled.toggled.addHandler { [weak self] _, _ in
            guard let self, let enabled = self.rgbEnabledControl else { return }
            guard self.model.rgbSettings.isEnabled != enabled.isOn else { return }
            self.updateRGBSettings { $0.isEnabled = enabled.isOn }
        }
        controls.children.append(enabled)

        let effect = ComboBox()
        effect.header = "Effect"
        effect.width = 250
        for item in RGBEffect.allCases {
            effect.items.append(item.displayName)
        }
        effect.selectedIndex = Int32(
            RGBEffect.allCases.firstIndex(of: model.rgbSettings.effect) ?? 0
        )
        rgbEffectControl = effect
        effect.selectionChanged.addHandler { [weak self] _, _ in
            guard let self, let effect = self.rgbEffectControl,
                effect.selectedIndex >= 0,
                Int(effect.selectedIndex) < RGBEffect.allCases.count
            else { return }
            let selected = RGBEffect.allCases[Int(effect.selectedIndex)]
            guard self.model.rgbSettings.effect != selected else { return }
            self.updateRGBSettings { $0.effect = selected }
        }
        controls.children.append(effect)
        controls.children.append(makeColorControl())
        content.children.append(controls)

        let levels = StackPanel()
        levels.orientation = .vertical
        levels.spacing = 14
        levels.children.append(makeLevelControl(for: .brightness))
        levels.children.append(makeLevelControl(for: .speed))
        content.children.append(levels)
        return content
    }

    /// Creates the native color-picker action and current-color swatch.
    ///
    /// - Returns: The configured color control group.
    private func makeColorControl() -> StackPanel {
        let group = StackPanel()
        group.orientation = .vertical
        group.spacing = 5
        group.children.append(
            WindowsTheme.makeText(
                text:
                    "Color",
                size: 12,
                color: WindowsTheme.makeColor(red: 191, green: 196, blue: 210)
            )
        )

        let button = Button()
        button.padding = Thickness(left: 12, top: 7, right: 14, bottom: 7)
        let row = StackPanel()
        row.orientation = .horizontal
        row.spacing = 9
        let rgb = model.rgbSettings.rgbColor
        let swatch = Border()
        swatch.width = 22
        swatch.height = 22
        swatch.cornerRadius = WindowsTheme.makeCornerRadius(all: 11)
        swatch.background = SolidColorBrush(rgb)
        swatch.borderBrush = WindowsTheme.makeBrush(red: 255, green: 255, blue: 255, alpha: 80)
        swatch.borderThickness = Thickness(left: 1, top: 1, right: 1, bottom: 1)
        rgbSwatch = swatch
        row.children.append(swatch)
        row.children.append(WindowsTheme.makeText(text: "Choose…", size: 14))
        button.content = row
        button.click.addHandler { [weak self] _, _ in self?.chooseColor() }
        group.children.append(button)
        return group
    }

    /// Presents the native color picker and applies an accepted color.
    private func chooseColor() {
        var color = model.rgbSettings.rgbColor
        guard keymap_choose_color(&color.r, &color.g, &color.b) != 0 else { return }
        updateRGBSettings { $0.setColor(color) }
    }

    /// Creates one bounded increment-and-decrement lighting control.
    ///
    /// - Parameter component: The RGB component controlled by the row.
    /// - Returns: The configured control group.
    private func makeLevelControl(for component: RGBLevelComponent) -> StackPanel {
        let settings = model.rgbSettings
        let value = component.value(in: settings)
        let maximum = component.maximumValue
        let group = StackPanel()
        group.orientation = .vertical
        group.spacing = 7
        group.width = 300
        let valueLabel = WindowsTheme.makeText(
            text:
                "\(component.title)  \(Int((Double(value) / Double(maximum) * 100).rounded()))%",
            size: 13,
            color: WindowsTheme.makeColor(red: 197, green: 202, blue: 216)
        )
        group.children.append(valueLabel)

        let row = StackPanel()
        row.orientation = .horizontal
        row.spacing = 9
        let minus = Button()
        minus.content = "−"
        minus.width = 38
        minus.isEnabled = value > 0
        minus.click.addHandler { [weak self] _, _ in
            self?.updateRGBSettings { settings in
                component.decrease(in: &settings)
            }
        }
        row.children.append(minus)

        let track = Grid()
        track.width = 195
        track.height = 8
        track.verticalAlignment = .center
        track.cornerRadius = WindowsTheme.makeCornerRadius(all: 4)
        track.background = WindowsTheme.makeBrush(red: 255, green: 255, blue: 255, alpha: 25)
        let fill = Border()
        fill.width = 195 * Double(value) / Double(maximum)
        fill.height = 8
        fill.horizontalAlignment = .left
        fill.cornerRadius = WindowsTheme.makeCornerRadius(all: 4)
        fill.background = WindowsTheme.makeBrush(red: 92, green: 140, blue: 255)
        track.children.append(fill)
        row.children.append(track)

        let plus = Button()
        plus.content = "+"
        plus.width = 38
        plus.isEnabled = value < maximum
        plus.click.addHandler { [weak self] _, _ in
            self?.updateRGBSettings { settings in
                component.increase(in: &settings)
            }
        }
        row.children.append(plus)
        group.children.append(row)
        if component == .brightness {
            brightnessLabel = valueLabel
            brightnessFill = fill
            brightnessMinus = minus
            brightnessPlus = plus
        } else {
            speedLabel = valueLabel
            speedFill = fill
            speedMinus = minus
            speedPlus = plus
        }
        return group
    }

    /// Synchronizes open flyout controls with shared lighting state.
    func synchronizeRGBControls() {
        let settings = model.rgbSettings
        if rgbEnabledControl?.isOn != settings.isEnabled {
            rgbEnabledControl?.isOn = settings.isEnabled
        }
        let effectIndex = Int32(RGBEffect.allCases.firstIndex(of: settings.effect) ?? 0)
        if rgbEffectControl?.selectedIndex != effectIndex {
            rgbEffectControl?.selectedIndex = effectIndex
        }
        rgbSwatch?.background = SolidColorBrush(settings.rgbColor)
        synchronizeLevel(for: .brightness, settings: settings)
        synchronizeLevel(for: .speed, settings: settings)
    }

    /// Synchronizes one existing level row with shared lighting state.
    ///
    /// - Parameters:
    ///   - component: The RGB component represented by the row.
    ///   - settings: The current shared RGB settings.
    private func synchronizeLevel(for component: RGBLevelComponent, settings: RGBSettings) {
        let value = component.value(in: settings)
        let maximum = component.maximumValue
        let controls: (label: TextBlock?, fill: Border?, minus: Button?, plus: Button?) =
            switch component {
            case .brightness:
                (brightnessLabel, brightnessFill, brightnessMinus, brightnessPlus)
            case .speed:
                (speedLabel, speedFill, speedMinus, speedPlus)
            }
        controls.label?.text = "\(component.title)  \(Int((Double(value) / Double(maximum) * 100).rounded()))%"
        controls.fill?.width = 195 * Double(value) / Double(maximum)
        controls.minus?.isEnabled = value > 0
        controls.plus?.isEnabled = value < maximum
    }
}
