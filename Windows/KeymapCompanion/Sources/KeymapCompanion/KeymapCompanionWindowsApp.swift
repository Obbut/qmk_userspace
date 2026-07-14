import CWindowsShell
import Dispatch
import Foundation
import KeymapCompanionCore
import UWP
import WinAppSDK
import WinUI

@main
final class KeymapCompanionWindowsApp: SwiftApplication {
    private var controller: WindowsAppController?

    required init() {
        super.init()
    }

    override class var runLoop: RunLoop {
        { _ in WindowsApplicationRunLoop.run() }
    }

    override func onLaunched(_ args: WinUI.LaunchActivatedEventArgs) {
        let controller = WindowsAppController()
        self.controller = controller
        controller.launch()
    }

    override func onShutdown(exitCode: Int32) {
        controller?.shutdown()
    }
}

/// Owns native Windows presentation and reduces shared transport events on the
/// WinUI thread.
private final class WindowsAppController: @unchecked Sendable {
    private let window = Window()
    private var state = CompanionState()
    private var contentBody: StackPanel?
    private lazy var monitor = WindowsHIDMonitor { [weak self] event in
        guard let controller = self else { return }
        DispatchQueue.main.async { controller.receive(event) }
    }
    private lazy var hud = WindowsLayerHUDController()
    private var tray: OpaquePointer?
    private var rgbTimer: Timer?
    private var rgbSettingsAwaitingAcknowledgement: RGBSettings?
    private var isExiting = false
    private var isMainWindowActive = true

    private weak var rgbEnabledControl: ToggleSwitch?
    private weak var rgbEffectControl: ComboBox?
    private weak var rgbSwatch: Border?
    private weak var brightnessLabel: TextBlock?
    private weak var brightnessFill: Border?
    private weak var brightnessMinus: Button?
    private weak var brightnessPlus: Button?
    private weak var speedLabel: TextBlock?
    private weak var speedFill: Border?
    private weak var speedMinus: Button?
    private weak var speedPlus: Button?

    func launch() {
        window.title = "Keymap Companion"
        try? window.appWindow.resize(SizeInt32(width: 1200, height: 780))
        window.content = makeContent()
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
                controller.handleTrayCommand(command)
            },
            Unmanaged.passUnretained(self).toOpaque()
        )
        monitor.start()
    }

    func shutdown() {
        rgbTimer?.invalidate()
        monitor.stop()
        hud.hideImmediately()
        if let tray {
            keymap_tray_destroy(tray)
            self.tray = nil
        }
    }

    private func handleTrayCommand(_ command: UInt32) {
        switch command {
        case UInt32(KEYMAP_TRAY_OPEN):
            try? window.appWindow.show(true)
        case UInt32(KEYMAP_TRAY_RECONNECT):
            reconnect()
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

    private func receive(_ event: KeyboardMonitorEvent) {
        let previous = WindowsViewSnapshot(state)
        switch event {
        case .searching, .keymap, .disconnected, .failed:
            if case .searching = event { cancelRGBUpdate() }
            if case .disconnected = event { cancelRGBUpdate() }
            if case .failed = event { cancelRGBUpdate() }
            state.apply(event)
            if case .keymap = event { hud.hideImmediately() }

        case let .state(report):
            guard state.keymapDefinition?.keyboardKind == report.keyboardKind else { return }
            let acceptsRGB = rgbTimer == nil
                && report.rgbSettings != nil
                && (rgbSettingsAwaitingAcknowledgement == nil
                    || rgbSettingsAwaitingAcknowledgement == report.rgbSettings)
            state.apply(event, acceptRGBSettings: acceptsRGB)
            if acceptsRGB { rgbSettingsAwaitingAcknowledgement = nil }
        }
        let current = WindowsViewSnapshot(state)
        renderChanges(from: previous, to: current)
        if previous.keymapDefinition != current.keymapDefinition
            || previous.effectiveLayerMask != current.effectiveLayerMask
            || previous.connectionStatus != current.connectionStatus {
            hud.update(
                definition: state.keymapDefinition,
                activeLayer: state.activeLayer,
                activeLayerMask: state.effectiveLayerMask,
                mainWindowIsVisible: isMainWindowActive
            )
        }
    }

    private func reconnect() {
        cancelRGBUpdate()
        hud.hideImmediately()
        state.apply(.searching)
        renderAll()
        monitor.restart()
    }

    private func cancelRGBUpdate() {
        rgbTimer?.invalidate()
        rgbTimer = nil
        rgbSettingsAwaitingAcknowledgement = nil
    }

    private func updateRGB(_ update: (inout RGBSettings) -> Void) {
        guard state.supportsRGBSettings else { return }
        var settings = state.rgbSettings
        update(&settings)
        guard settings != state.rgbSettings else { return }
        state.setRGBSettings(settings)
        synchronizeRGBControls()

        rgbTimer?.invalidate()
        rgbTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self, settings] _ in
            guard let self, self.state.rgbSettings == settings else { return }
            self.rgbTimer = nil
            self.rgbSettingsAwaitingAcknowledgement = settings
            self.monitor.applyRGBSettings(settings)
        }
    }

    private func makeContent() -> UIElement {
        clearRGBControlReferences()
        let body = StackPanel()
        body.orientation = .vertical
        body.spacing = 20
        body.margin = Thickness(left: 32, top: 28, right: 32, bottom: 36)
        body.requestedTheme = .dark

        body.children.append(makeHeader())
        body.children.append(makeConnectionInfo())

        if let definition = state.keymapDefinition {
            body.children.append(makeKeyboardCard(definition))
        } else {
            body.children.append(makeEmptyState())
        }
        if state.supportsRGBSettings {
            body.children.append(makeRGBCard())
        }
        contentBody = body

        let scroll = ScrollViewer()
        scroll.background = WindowsTheme.brush(23, 25, 32)
        scroll.verticalScrollBarVisibility = .auto
        scroll.horizontalScrollBarVisibility = .disabled
        scroll.content = body
        return scroll
    }

    private func renderChanges(
        from previous: WindowsViewSnapshot,
        to current: WindowsViewSnapshot
    ) {
        guard previous != current else { return }
        let structureChanged = previous.connectionStatus != current.connectionStatus
            || previous.keyboardKind != current.keyboardKind
            || previous.keymapDefinition != current.keymapDefinition
            || previous.supportsRGBSettings != current.supportsRGBSettings
        if structureChanged {
            renderAll()
            return
        }

        if previous.effectiveLayerMask != current.effectiveLayerMask,
           let definition = state.keymapDefinition {
            contentBody?.children.setAt(2, makeKeyboardCard(definition))
        }
        if previous.rgbSettings != current.rgbSettings {
            synchronizeRGBControls()
        }
    }

    private func renderAll() {
        window.content = makeContent()
    }

    private func clearRGBControlReferences() {
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

    private func makeHeader() -> UIElement {
        let header = StackPanel()
        header.orientation = .horizontal
        header.spacing = 14
        header.verticalAlignment = .center

        let title = WindowsTheme.text("Keymap Companion", size: 30)
        title.fontWeight = FontWeights.semiBold
        title.verticalAlignment = .center
        header.children.append(title)
        header.children.append(makeStatusBadge())

        let reconnect = Button()
        reconnect.content = "Reconnect"
        reconnect.padding = Thickness(left: 16, top: 8, right: 16, bottom: 8)
        reconnect.click.addHandler { [weak self] _, _ in self?.reconnect() }
        try? AutomationProperties.setName(reconnect, "Reconnect keyboard")
        header.children.append(reconnect)
        return header
    }

    private func makeStatusBadge() -> Border {
        let (label, color): (String, Color) = switch state.connectionStatus {
        case .searching: ("Searching", WindowsTheme.color(98, 170, 255))
        case .connected: ("Connected", WindowsTheme.color(74, 210, 140))
        case .disconnected: ("Disconnected", WindowsTheme.color(247, 184, 77))
        case .failed: ("Needs attention", WindowsTheme.color(255, 106, 115))
        }
        let badge = Border()
        badge.background = SolidColorBrush(Color(a: 34, r: color.r, g: color.g, b: color.b))
        badge.borderBrush = SolidColorBrush(Color(a: 100, r: color.r, g: color.g, b: color.b))
        badge.borderThickness = Thickness(left: 1, top: 1, right: 1, bottom: 1)
        badge.cornerRadius = WindowsTheme.corners(12)
        badge.padding = Thickness(left: 10, top: 4, right: 10, bottom: 4)
        let text = WindowsTheme.text(label, size: 12, color: color)
        text.fontWeight = FontWeights.semiBold
        badge.child = text
        return badge
    }

    private func makeConnectionInfo() -> InfoBar {
        let info = InfoBar()
        info.isOpen = true
        info.isClosable = false
        info.isIconVisible = true
        switch state.connectionStatus {
        case .searching:
            info.severity = .informational
            info.title = "Looking for your keyboard"
            info.message = "Connect an Elora Rev2 or Kyria Rev4 running the companion protocol."
        case .connected:
            info.severity = .success
            info.title = state.keyboardKind?.displayName ?? "Keyboard connected"
            info.message = "Live layer and lighting state is updating over Raw HID."
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

    private func makeEmptyState() -> Border {
        let content = StackPanel()
        content.orientation = .vertical
        content.spacing = 8
        let title = WindowsTheme.text("Your keymap will appear here", size: 21)
        title.fontWeight = FontWeights.semiBold
        content.children.append(title)
        content.children.append(WindowsTheme.text(
            "Keymap Companion downloads the keymap compiled into QMK and verifies its fingerprint before drawing it.",
            size: 14,
            color: WindowsTheme.color(177, 184, 201)
        ))
        let card = WindowsTheme.card(content: content, padding: 28)
        card.minHeight = 190
        return card
    }

    private func makeKeyboardCard(_ definition: KeymapDefinition) -> Border {
        let content = StackPanel()
        content.orientation = .vertical
        content.spacing = 16

        let heading = StackPanel()
        heading.orientation = .horizontal
        heading.spacing = 12
        let name = WindowsTheme.text(definition.keyboardKind.displayName, size: 21)
        name.fontWeight = FontWeights.semiBold
        heading.children.append(name)
        heading.children.append(WindowsTheme.text(
            "Active layer: \(state.activeLayer.displayName)",
            size: 14,
            color: WindowsTheme.color(158, 183, 255)
        ))
        content.children.append(heading)
        content.children.append(makeLayerStrip())

        let boardScroll = ScrollViewer()
        boardScroll.horizontalScrollBarVisibility = .auto
        boardScroll.verticalScrollBarVisibility = .disabled
        boardScroll.content = WindowsKeymapRenderer.make(
            definition: definition,
            activeLayerMask: state.effectiveLayerMask
        )
        content.children.append(boardScroll)
        return WindowsTheme.card(content: content, padding: 22)
    }

    private func makeLayerStrip() -> StackPanel {
        let strip = StackPanel()
        strip.orientation = .horizontal
        strip.spacing = 8
        for layer in KeymapLayer.allCases {
            let isActive = layer.isActive(in: state.effectiveLayerMask)
            let pill = Border()
            pill.cornerRadius = WindowsTheme.corners(10)
            pill.padding = Thickness(left: 10, top: 4, right: 10, bottom: 4)
            pill.background = isActive
                ? WindowsTheme.brush(73, 105, 184, alpha: 210)
                : WindowsTheme.brush(255, 255, 255, alpha: 14)
            let label = WindowsTheme.text(
                layer.displayName,
                size: 12,
                color: isActive ? WindowsTheme.color(255, 255, 255) : WindowsTheme.color(157, 164, 181)
            )
            label.fontWeight = isActive ? FontWeights.semiBold : FontWeights.normal
            pill.child = label
            strip.children.append(pill)
        }
        return strip
    }

    private func makeRGBCard() -> Border {
        let content = StackPanel()
        content.orientation = .vertical
        content.spacing = 16

        let title = WindowsTheme.text("Keyboard lighting", size: 21)
        title.fontWeight = FontWeights.semiBold
        content.children.append(title)

        let controls = StackPanel()
        controls.orientation = .horizontal
        controls.spacing = 18
        controls.verticalAlignment = .bottom

        let enabled = ToggleSwitch()
        enabled.header = "Lighting"
        enabled.onContent = "On"
        enabled.offContent = "Off"
        enabled.isOn = state.rgbSettings.isEnabled
        rgbEnabledControl = enabled
        enabled.toggled.addHandler { [weak self, weak enabled] _, _ in
            guard let self, let enabled else { return }
            self.updateRGB { $0.isEnabled = enabled.isOn }
        }
        controls.children.append(enabled)

        let effect = ComboBox()
        effect.header = "Effect"
        effect.width = 250
        for item in RGBEffect.allCases { effect.items.append(item.displayName) }
        effect.selectedIndex = Int32(
            RGBEffect.allCases.firstIndex(of: state.rgbSettings.effect) ?? 0
        )
        rgbEffectControl = effect
        effect.selectionChanged.addHandler { [weak self, weak effect] _, _ in
            guard let self, let effect,
                  effect.selectedIndex >= 0,
                  Int(effect.selectedIndex) < RGBEffect.allCases.count else { return }
            let selected = RGBEffect.allCases[Int(effect.selectedIndex)]
            self.updateRGB { $0.effect = selected }
        }
        controls.children.append(effect)
        controls.children.append(makeColorButton())
        content.children.append(controls)

        let levels = StackPanel()
        levels.orientation = .horizontal
        levels.spacing = 24
        levels.children.append(makeLevelControl(
            title: "Brightness",
            value: state.rgbSettings.brightness,
            maximum: RGBSettings.maximumBrightness,
            step: 8,
            isBrightness: true
        ))
        levels.children.append(makeLevelControl(
            title: "Animation speed",
            value: state.rgbSettings.speed,
            maximum: RGBSettings.maximumSpeed,
            step: 16,
            isBrightness: false
        ))
        content.children.append(levels)
        return WindowsTheme.card(content: content, padding: 22)
    }

    private func makeColorButton() -> StackPanel {
        let group = StackPanel()
        group.orientation = .vertical
        group.spacing = 5
        group.children.append(WindowsTheme.text("Color", size: 12, color: WindowsTheme.color(191, 196, 210)))

        let button = Button()
        button.padding = Thickness(left: 12, top: 7, right: 14, bottom: 7)
        let row = StackPanel()
        row.orientation = .horizontal
        row.spacing = 9
        let rgb = state.rgbSettings.rgbColor
        let swatch = Border()
        swatch.width = 22
        swatch.height = 22
        swatch.cornerRadius = WindowsTheme.corners(11)
        swatch.background = SolidColorBrush(rgb)
        swatch.borderBrush = WindowsTheme.brush(255, 255, 255, alpha: 80)
        swatch.borderThickness = Thickness(left: 1, top: 1, right: 1, bottom: 1)
        rgbSwatch = swatch
        row.children.append(swatch)
        row.children.append(WindowsTheme.text("Choose…", size: 14))
        button.content = row
        button.click.addHandler { [weak self] _, _ in self?.chooseColor() }
        group.children.append(button)
        return group
    }

    private func chooseColor() {
        var color = state.rgbSettings.rgbColor
        guard keymap_choose_color(&color.r, &color.g, &color.b) != 0 else { return }
        updateRGB { $0.setRGBColor(color) }
    }

    private func makeLevelControl(
        title: String,
        value: UInt8,
        maximum: UInt8,
        step: UInt8,
        isBrightness: Bool
    ) -> StackPanel {
        let group = StackPanel()
        group.orientation = .vertical
        group.spacing = 7
        group.width = 300
        let valueLabel = WindowsTheme.text(
            "\(title)  \(Int((Double(value) / Double(maximum) * 100).rounded()))%",
            size: 13,
            color: WindowsTheme.color(197, 202, 216)
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
            self?.updateRGB { settings in
                if isBrightness {
                    settings.brightness = UInt8(clamping: Int(settings.brightness) - Int(step))
                } else {
                    settings.speed = UInt8(clamping: Int(settings.speed) - Int(step))
                }
            }
        }
        row.children.append(minus)

        let track = Grid()
        track.width = 195
        track.height = 8
        track.verticalAlignment = .center
        track.cornerRadius = WindowsTheme.corners(4)
        track.background = WindowsTheme.brush(255, 255, 255, alpha: 25)
        let fill = Border()
        fill.width = 195 * Double(value) / Double(maximum)
        fill.height = 8
        fill.horizontalAlignment = .left
        fill.cornerRadius = WindowsTheme.corners(4)
        fill.background = WindowsTheme.brush(92, 140, 255)
        track.children.append(fill)
        row.children.append(track)

        let plus = Button()
        plus.content = "+"
        plus.width = 38
        plus.isEnabled = value < maximum
        plus.click.addHandler { [weak self] _, _ in
            self?.updateRGB { settings in
                if isBrightness {
                    settings.brightness = UInt8(clamping: Int(settings.brightness) + Int(step))
                } else {
                    settings.speed = UInt8(clamping: Int(settings.speed) + Int(step))
                }
            }
        }
        row.children.append(plus)
        group.children.append(row)
        if isBrightness {
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

    private func synchronizeRGBControls() {
        let settings = state.rgbSettings
        if rgbEnabledControl?.isOn != settings.isEnabled {
            rgbEnabledControl?.isOn = settings.isEnabled
        }
        let effectIndex = Int32(RGBEffect.allCases.firstIndex(of: settings.effect) ?? 0)
        if rgbEffectControl?.selectedIndex != effectIndex {
            rgbEffectControl?.selectedIndex = effectIndex
        }
        rgbSwatch?.background = SolidColorBrush(settings.rgbColor)
        synchronizeLevel(
            title: "Brightness",
            value: settings.brightness,
            maximum: RGBSettings.maximumBrightness,
            label: brightnessLabel,
            fill: brightnessFill,
            minus: brightnessMinus,
            plus: brightnessPlus
        )
        synchronizeLevel(
            title: "Animation speed",
            value: settings.speed,
            maximum: RGBSettings.maximumSpeed,
            label: speedLabel,
            fill: speedFill,
            minus: speedMinus,
            plus: speedPlus
        )
    }

    private func synchronizeLevel(
        title: String,
        value: UInt8,
        maximum: UInt8,
        label: TextBlock?,
        fill: Border?,
        minus: Button?,
        plus: Button?
    ) {
        label?.text = "\(title)  \(Int((Double(value) / Double(maximum) * 100).rounded()))%"
        fill?.width = 195 * Double(value) / Double(maximum)
        minus?.isEnabled = value > 0
        plus?.isEnabled = value < maximum
    }
}

private struct WindowsViewSnapshot: Equatable {
    let connectionStatus: ConnectionStatus
    let keyboardKind: KeyboardKind?
    let keymapDefinition: KeymapDefinition?
    let effectiveLayerMask: UInt32
    let supportsRGBSettings: Bool
    let rgbSettings: RGBSettings

    init(_ state: CompanionState) {
        connectionStatus = state.connectionStatus
        keyboardKind = state.keyboardKind
        keymapDefinition = state.keymapDefinition
        effectiveLayerMask = state.effectiveLayerMask
        supportsRGBSettings = state.supportsRGBSettings
        rgbSettings = state.rgbSettings
    }
}

private extension RGBSettings {
    var rgbColor: Color {
        let h = Double(hue) / 255
        let s = Double(saturation) / 255
        let v = Double(brightness) / Double(Self.maximumBrightness)
        let i = Int(floor(h * 6)) % 6
        let f = h * 6 - floor(h * 6)
        let p = v * (1 - s)
        let q = v * (1 - f * s)
        let t = v * (1 - (1 - f) * s)
        let components: (Double, Double, Double) = switch i {
        case 0: (v, t, p)
        case 1: (q, v, p)
        case 2: (p, v, t)
        case 3: (p, q, v)
        case 4: (t, p, v)
        default: (v, p, q)
        }
        return Color(
            a: 255,
            r: UInt8(clamping: Int((components.0 * 255).rounded())),
            g: UInt8(clamping: Int((components.1 * 255).rounded())),
            b: UInt8(clamping: Int((components.2 * 255).rounded()))
        )
    }

    mutating func setRGBColor(_ color: Color) {
        let red = Double(color.r) / 255
        let green = Double(color.g) / 255
        let blue = Double(color.b) / 255
        let maximum = max(red, green, blue)
        let minimum = min(red, green, blue)
        let delta = maximum - minimum
        var selectedHue = 0.0
        if delta != 0 {
            if maximum == red {
                selectedHue = ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
            } else if maximum == green {
                selectedHue = (blue - red) / delta + 2
            } else {
                selectedHue = (red - green) / delta + 4
            }
            selectedHue /= 6
            if selectedHue < 0 { selectedHue += 1 }
        }
        hue = Self.byte(from: selectedHue, maximum: 255)
        saturation = Self.byte(from: maximum == 0 ? 0 : delta / maximum, maximum: 255)
        brightness = Self.byte(from: maximum, maximum: Self.maximumBrightness)
    }
}
