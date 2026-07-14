import KeymapCompanionCore
import UWP
import WindowsFoundation
import WinUI

/// A retained WinUI keymap surface. Layer changes update the existing native
/// elements instead of allocating and laying out the complete keyboard again.
@MainActor
final class WindowsKeymapSurface {
    let canvas = Canvas()

    private var renderedLayerMask: UInt32?
    private var keys: [RenderedKey] = []
    private var encoder: RenderedEncoder!

    init(
        definition: KeymapDefinition,
        activeLayerMask: UInt32,
        scale: Double = 0.84
    ) {
        canvas.width = definition.geometry.canvasWidth * scale
        canvas.height = definition.geometry.canvasHeight * scale

        keys = definition.positionedKeys.map { positionedKey in
            let rendered = Self.makeKey(
                key: positionedKey.key,
                placement: positionedKey.placement,
                scale: scale
            )
            canvas.children.append(rendered.border)
            return rendered
        }
        encoder = Self.makeEncoder(definition.rightEncoder, scale: scale, canvas: canvas)
        update(activeLayerMask: activeLayerMask)
    }

    func update(activeLayerMask: UInt32) {
        guard renderedLayerMask != activeLayerMask else { return }
        renderedLayerMask = activeLayerMask
        let activeLayer = KeymapLayer.highestActiveLayer(inLayerMask: activeLayerMask)

        for index in keys.indices {
            let legend = keys[index].key.resolvedLegend(forActiveLayerMask: activeLayerMask)
            let isDirect = keys[index].key.isDirectlyMapped(on: activeLayer)
            if keys[index].legend != legend {
                keys[index].legend = legend
                keys[index].label.text = Self.displayText(for: legend)
                keys[index].border.background = Self.background(for: legend.style)
                try? AutomationProperties.setName(
                    keys[index].border,
                    legend.label.isEmpty ? "Unassigned key" : legend.label
                )
            }
            if keys[index].isDirect != isDirect {
                keys[index].isDirect = isDirect
                keys[index].border.borderBrush = WindowsTheme.brush(
                    255, 255, 255,
                    alpha: isDirect ? 48 : 26
                )
                keys[index].border.opacity = isDirect ? 1 : 0.68
            }
        }

        updateEncoder(activeLayerMask: activeLayerMask, activeLayer: activeLayer)
    }

    private func updateEncoder(activeLayerMask: UInt32, activeLayer: KeymapLayer) {
        let pressLegend = encoder.pressKey.resolvedLegend(forActiveLayerMask: activeLayerMask)
        if encoder.pressLegend != pressLegend {
            encoder.pressLegend = pressLegend
            encoder.pressLabel.text = Self.displayText(for: pressLegend)
            try? AutomationProperties.setName(
                encoder.knob,
                "Encoder press: \(pressLegend.label)"
            )
        }
        updateEncoderAction(
            &encoder.counterclockwise,
            activeLayerMask: activeLayerMask,
            activeLayer: activeLayer
        )
        updateEncoderAction(
            &encoder.clockwise,
            activeLayerMask: activeLayerMask,
            activeLayer: activeLayer
        )
    }

    private func updateEncoderAction(
        _ action: inout RenderedEncoderAction,
        activeLayerMask: UInt32,
        activeLayer: KeymapLayer
    ) {
        let legend = action.key.resolvedLegend(forActiveLayerMask: activeLayerMask)
        let isDirect = action.key.isDirectlyMapped(on: activeLayer)
        if action.legend != legend {
            action.legend = legend
            action.label.text = "\(action.arrow) \(Self.displayText(for: legend))"
            try? AutomationProperties.setName(action.border, "Encoder turn: \(legend.label)")
        }
        if action.isDirect != isDirect {
            action.isDirect = isDirect
            action.border.opacity = isDirect ? 1 : 0.68
        }
    }

    private static func makeKey(
        key: KeymapKey,
        placement: PhysicalKeyPlacement,
        scale: Double
    ) -> RenderedKey {
        let size = 50 * scale
        let border = Border()
        border.width = size
        border.height = size
        border.cornerRadius = WindowsTheme.corners(8 * scale)
        border.borderThickness = Thickness(left: 1, top: 1, right: 1, bottom: 1)
        border.rotation = Float(placement.rotationDegrees)
        border.centerPoint = Vector3(x: Float(size / 2), y: Float(size / 2), z: 0)

        let label = WindowsTheme.text("", size: max(9, 11.5 * scale))
        label.textAlignment = .center
        label.horizontalAlignment = .center
        label.verticalAlignment = .center
        label.textWrapping = .wrapWholeWords
        label.maxLines = 2
        label.margin = Thickness(left: 3, top: 1, right: 3, bottom: 1)
        border.child = label

        try? Canvas.setLeft(border, placement.centerX * scale - size / 2)
        try? Canvas.setTop(border, placement.centerY * scale - size / 2)
        return RenderedKey(key: key, border: border, label: label)
    }

    private static func makeEncoder(
        _ definition: KeymapEncoder,
        scale: Double,
        canvas: Canvas
    ) -> RenderedEncoder {
        let centerX = definition.placement.centerX * scale
        let centerY = definition.placement.centerY * scale
        let knobSize = 46 * scale

        let knob = Border()
        knob.width = knobSize
        knob.height = knobSize
        knob.cornerRadius = WindowsTheme.corners(knobSize / 2)
        knob.background = WindowsTheme.brush(52, 56, 68)
        knob.borderBrush = WindowsTheme.brush(255, 255, 255, alpha: 58)
        knob.borderThickness = Thickness(left: 2, top: 2, right: 2, bottom: 2)
        let pressLabel = WindowsTheme.text("", size: 9 * scale)
        pressLabel.textAlignment = .center
        pressLabel.horizontalAlignment = .center
        pressLabel.verticalAlignment = .center
        pressLabel.maxLines = 2
        knob.child = pressLabel
        try? Canvas.setLeft(knob, centerX - knobSize / 2)
        try? Canvas.setTop(knob, centerY - knobSize / 2)
        canvas.children.append(knob)

        // Keep both turn actions in the center gap to the left of the knob. The
        // first key in the right half begins too close to the physical encoder
        // for a trailing action pill without overlap.
        let counterclockwise = makeEncoderAction(
            arrow: "↶",
            key: definition.counterclockwiseKey,
            x: centerX - 186 * scale,
            y: centerY - 18 * scale,
            scale: scale
        )
        canvas.children.append(counterclockwise.border)
        let clockwise = makeEncoderAction(
            arrow: "↷",
            key: definition.clockwiseKey,
            x: centerX - 86 * scale,
            y: centerY - 18 * scale,
            scale: scale
        )
        canvas.children.append(clockwise.border)

        return RenderedEncoder(
            pressKey: definition.pressKey,
            knob: knob,
            pressLabel: pressLabel,
            counterclockwise: counterclockwise,
            clockwise: clockwise
        )
    }

    private static func makeEncoderAction(
        arrow: String,
        key: KeymapKey,
        x: Double,
        y: Double,
        scale: Double
    ) -> RenderedEncoderAction {
        let width = 52 * scale
        let height = 36 * scale
        let border = Border()
        border.width = width
        border.height = height
        border.cornerRadius = WindowsTheme.corners(9 * scale)
        border.background = WindowsTheme.brush(43, 46, 57)
        border.borderBrush = WindowsTheme.brush(255, 255, 255, alpha: 34)
        border.borderThickness = Thickness(left: 1, top: 1, right: 1, bottom: 1)
        let label = WindowsTheme.text("", size: max(8, 9.5 * scale))
        label.textAlignment = .center
        label.horizontalAlignment = .center
        label.verticalAlignment = .center
        label.maxLines = 2
        border.child = label
        try? Canvas.setLeft(border, x)
        try? Canvas.setTop(border, y)
        return RenderedEncoderAction(arrow: arrow, key: key, border: border, label: label)
    }

    private static func displayText(for legend: KeyLegend) -> String {
        guard let symbol = legend.symbol else { return legend.label }
        return switch symbol {
        case .returnKey: "↵"
        case .escape: "Esc"
        case .deleteBackward: "⌫"
        case .tab: "⇥"
        case .space: "Space"
        case .capsLock: "Caps"
        case .deleteForward: "⌦"
        case .arrowRight: "→"
        case .arrowLeft: "←"
        case .arrowDown: "↓"
        case .arrowUp: "↑"
        case .mute: "Mute"
        case .volumeUp: "Vol +"
        case .volumeDown: "Vol −"
        case .nextTrack: "Next"
        case .previousTrack: "Prev"
        case .playPause: "Play"
        case .control: "Ctrl"
        case .shift: "Shift"
        case .option: "Alt"
        case .command: "Win"
        }
    }

    private static func background(for style: KeyStyle) -> SolidColorBrush {
        switch style {
        case .standard: WindowsTheme.brush(43, 46, 57)
        case .purple: WindowsTheme.brush(83, 55, 132)
        case .magenta: WindowsTheme.brush(128, 45, 105)
        case .blue: WindowsTheme.brush(40, 78, 139)
        case .yellow: WindowsTheme.brush(119, 91, 31)
        case .cyan: WindowsTheme.brush(31, 103, 116)
        case .green: WindowsTheme.brush(35, 105, 70)
        case .darkGreen: WindowsTheme.brush(28, 76, 56)
        case .red: WindowsTheme.brush(132, 47, 55)
        case .orange: WindowsTheme.brush(137, 70, 34)
        }
    }
}

private struct RenderedKey {
    let key: KeymapKey
    let border: Border
    let label: TextBlock
    var legend: KeyLegend?
    var isDirect: Bool?
}

private struct RenderedEncoder {
    let pressKey: KeymapKey
    let knob: Border
    let pressLabel: TextBlock
    var pressLegend: KeyLegend?
    var counterclockwise: RenderedEncoderAction
    var clockwise: RenderedEncoderAction
}

private struct RenderedEncoderAction {
    let arrow: String
    let key: KeymapKey
    let border: Border
    let label: TextBlock
    var legend: KeyLegend?
    var isDirect: Bool?
}
