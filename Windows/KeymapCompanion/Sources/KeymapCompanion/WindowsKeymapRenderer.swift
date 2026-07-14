import KeymapCompanionCore
import UWP
import WindowsFoundation
import WinUI

/// A WinUI-native renderer driven by the same platform-neutral renderer input as
/// the macOS SwiftUI Canvas implementation.
enum WindowsKeymapRenderer {
    static func make(
        definition: KeymapDefinition,
        activeLayerMask: UInt32,
        scale: Double = 0.84
    ) -> Canvas {
        let canvas = Canvas()
        canvas.width = definition.geometry.canvasWidth * scale
        canvas.height = definition.geometry.canvasHeight * scale

        let activeLayer = KeymapLayer.highestActiveLayer(in: activeLayerMask)
        for positionedKey in definition.positionedKeys {
            let legend = positionedKey.key.resolvedLegend(activeLayerMask: activeLayerMask)
            let key = makeKey(
                legend: legend,
                placement: positionedKey.placement,
                isDirect: positionedKey.key.isDirectlyMapped(on: activeLayer),
                scale: scale
            )
            canvas.children.append(key)
        }

        addEncoder(
            definition.rightEncoder,
            activeLayerMask: activeLayerMask,
            activeLayer: activeLayer,
            scale: scale,
            to: canvas
        )
        return canvas
    }

    private static func makeKey(
        legend: KeyLegend,
        placement: PhysicalKeyPlacement,
        isDirect: Bool,
        scale: Double
    ) -> Border {
        let size = 50 * scale
        let key = Border()
        key.width = size
        key.height = size
        key.cornerRadius = WindowsTheme.corners(8 * scale)
        key.background = background(for: legend.style)
        key.borderBrush = WindowsTheme.brush(255, 255, 255, alpha: isDirect ? 48 : 26)
        key.borderThickness = Thickness(left: 1, top: 1, right: 1, bottom: 1)
        key.opacity = isDirect ? 1 : 0.68
        key.rotation = Float(placement.rotationDegrees)
        key.centerPoint = Vector3(x: Float(size / 2), y: Float(size / 2), z: 0)

        let label = WindowsTheme.text(displayText(for: legend), size: max(9, 11.5 * scale))
        label.textAlignment = .center
        label.horizontalAlignment = .center
        label.verticalAlignment = .center
        label.textWrapping = .wrapWholeWords
        label.maxLines = 2
        label.margin = Thickness(left: 3, top: 1, right: 3, bottom: 1)
        key.child = label

        try? Canvas.setLeft(key, placement.centerX * scale - size / 2)
        try? Canvas.setTop(key, placement.centerY * scale - size / 2)
        try? AutomationProperties.setName(key, legend.label.isEmpty ? "Unassigned key" : legend.label)
        return key
    }

    private static func addEncoder(
        _ encoder: KeymapEncoder,
        activeLayerMask: UInt32,
        activeLayer: KeymapLayer,
        scale: Double,
        to canvas: Canvas
    ) {
        let centerX = encoder.placement.centerX * scale
        let centerY = encoder.placement.centerY * scale
        let knobSize = 46 * scale

        let knob = Border()
        knob.width = knobSize
        knob.height = knobSize
        knob.cornerRadius = WindowsTheme.corners(knobSize / 2)
        knob.background = WindowsTheme.brush(52, 56, 68)
        knob.borderBrush = WindowsTheme.brush(255, 255, 255, alpha: 58)
        knob.borderThickness = Thickness(left: 2, top: 2, right: 2, bottom: 2)
        let pressLegend = encoder.pressKey.resolvedLegend(activeLayerMask: activeLayerMask)
        let press = WindowsTheme.text(displayText(for: pressLegend), size: 9 * scale)
        press.textAlignment = .center
        press.horizontalAlignment = .center
        press.verticalAlignment = .center
        press.maxLines = 2
        knob.child = press
        try? Canvas.setLeft(knob, centerX - knobSize / 2)
        try? Canvas.setTop(knob, centerY - knobSize / 2)
        try? AutomationProperties.setName(knob, "Encoder press: \(pressLegend.label)")
        canvas.children.append(knob)

        let counterClockwise = encoder.counterClockwiseKey.resolvedLegend(activeLayerMask: activeLayerMask)
        let clockwise = encoder.clockwiseKey.resolvedLegend(activeLayerMask: activeLayerMask)
        // Keep both turn actions in the center gap to the left of the knob. The
        // first key in the right half begins too close to the physical encoder
        // for a trailing action pill without overlap.
        canvas.children.append(makeEncoderAction(
            arrow: "↶",
            legend: counterClockwise,
            x: centerX - 186 * scale,
            y: centerY - 18 * scale,
            isDirect: encoder.counterClockwiseKey.isDirectlyMapped(on: activeLayer),
            scale: scale
        ))
        canvas.children.append(makeEncoderAction(
            arrow: "↷",
            legend: clockwise,
            x: centerX - 86 * scale,
            y: centerY - 18 * scale,
            isDirect: encoder.clockwiseKey.isDirectlyMapped(on: activeLayer),
            scale: scale
        ))
    }

    private static func makeEncoderAction(
        arrow: String,
        legend: KeyLegend,
        x: Double,
        y: Double,
        isDirect: Bool,
        scale: Double
    ) -> Border {
        let width = 52 * scale
        let height = 36 * scale
        let pill = Border()
        pill.width = width
        pill.height = height
        pill.cornerRadius = WindowsTheme.corners(9 * scale)
        pill.background = WindowsTheme.brush(43, 46, 57)
        pill.borderBrush = WindowsTheme.brush(255, 255, 255, alpha: 34)
        pill.borderThickness = Thickness(left: 1, top: 1, right: 1, bottom: 1)
        pill.opacity = isDirect ? 1 : 0.68
        let label = WindowsTheme.text("\(arrow) \(displayText(for: legend))", size: max(8, 9.5 * scale))
        label.textAlignment = .center
        label.horizontalAlignment = .center
        label.verticalAlignment = .center
        label.maxLines = 2
        pill.child = label
        try? Canvas.setLeft(pill, x)
        try? Canvas.setTop(pill, y)
        try? AutomationProperties.setName(pill, "Encoder turn: \(legend.label)")
        return pill
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
