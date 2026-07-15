import KeymapCompanionCore
import UWP
import WindowsFoundation
import WinUI

/// Element factories and platform legend presentation for the retained keymap surface.
extension WindowsKeymapSurface {
    /// Creates one visible switch element.
    ///
    /// - Parameters:
    ///   - key: The firmware-owned layer mappings.
    ///   - placement: The switch's logical placement.
    ///   - scale: The logical-to-device-independent-pixel scale.
    /// - Returns: The retained switch element.
    static func makeKey(
        key: KeymapKey,
        placement: PhysicalKeyPlacement,
        scale: Double
    ) -> RenderedKey {
        let width = 50 * placement.width * scale
        let height = 50 * placement.height * scale
        let border = Border()
        border.width = width
        border.height = height
        border.cornerRadius = WindowsTheme.makeCornerRadius(all: 8 * scale)
        border.borderThickness = Thickness(left: 1, top: 1, right: 1, bottom: 1)
        border.rotation = Float(placement.rotationDegrees)
        border.centerPoint = Vector3(x: Float(width / 2), y: Float(height / 2), z: 0)

        let label = WindowsTheme.makeText(text: "", size: max(9, 11.5 * scale))
        label.textAlignment = .center
        label.horizontalAlignment = .center
        label.verticalAlignment = .center
        label.textWrapping = .wrapWholeWords
        label.maxLines = 2
        label.margin = Thickness(left: 3, top: 1, right: 3, bottom: 1)
        border.child = label

        try? Canvas.setLeft(border, placement.centerX * scale - width / 2)
        try? Canvas.setTop(border, placement.centerY * scale - height / 2)
        return RenderedKey(key: key, border: border, label: label)
    }

    /// Creates one encoder and its two turn-action elements.
    ///
    /// - Parameters:
    ///   - definition: The firmware-owned encoder mappings and placement.
    ///   - scale: The logical-to-device-independent-pixel scale.
    ///   - canvas: The canvas that owns the created elements.
    /// - Returns: The retained encoder elements.
    static func makeEncoder(
        definition: KeymapEncoder,
        scale: Double,
        canvas: Canvas
    ) -> RenderedEncoder {
        let centerX = definition.placement.centerX * scale
        let centerY = definition.placement.centerY * scale
        let knobSize = 46 * scale

        let knob = Border()
        knob.width = knobSize
        knob.height = knobSize
        knob.cornerRadius = WindowsTheme.makeCornerRadius(all: knobSize / 2)
        knob.background = WindowsTheme.makeBrush(red: 52, green: 56, blue: 68)
        knob.borderBrush = WindowsTheme.makeBrush(red: 255, green: 255, blue: 255, alpha: 58)
        knob.borderThickness = Thickness(left: 2, top: 2, right: 2, bottom: 2)
        let pressLabel = WindowsTheme.makeText(text: "", size: 9 * scale)
        pressLabel.textAlignment = .center
        pressLabel.horizontalAlignment = .center
        pressLabel.verticalAlignment = .center
        pressLabel.maxLines = 2
        knob.child = pressLabel
        try? Canvas.setLeft(knob, centerX - knobSize / 2)
        try? Canvas.setTop(knob, centerY - knobSize / 2)
        canvas.children.append(knob)

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

    /// Creates one encoder-turn action element.
    ///
    /// - Parameters:
    ///   - arrow: The platform turn-direction glyph.
    ///   - key: The firmware-owned layer mappings.
    ///   - x: The element's horizontal canvas coordinate.
    ///   - y: The element's vertical canvas coordinate.
    ///   - scale: The logical-to-device-independent-pixel scale.
    /// - Returns: The retained encoder-action element.
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
        border.cornerRadius = WindowsTheme.makeCornerRadius(all: 9 * scale)
        border.background = WindowsTheme.makeBrush(red: 43, green: 46, blue: 57)
        border.borderBrush = WindowsTheme.makeBrush(red: 255, green: 255, blue: 255, alpha: 34)
        border.borderThickness = Thickness(left: 1, top: 1, right: 1, bottom: 1)
        let label = WindowsTheme.makeText(text: "", size: max(8, 9.5 * scale))
        label.textAlignment = .center
        label.horizontalAlignment = .center
        label.verticalAlignment = .center
        label.maxLines = 2
        border.child = label
        try? Canvas.setLeft(border, x)
        try? Canvas.setTop(border, y)
        return RenderedEncoderAction(arrow: arrow, key: key, border: border, label: label)
    }

    /// Returns compact Windows text for a platform-neutral key legend.
    ///
    /// - Parameter legend: The platform-neutral legend to display.
    /// - Returns: Compact Windows text.
    static func displayText(for legend: KeyLegend) -> String {
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
        case .camera: "Screenshot"
        case .windowManagement: "Window"
        case .lockedPointer: "Drag Lock"
        case .bluetooth: "Bluetooth"
        case .battery: "Battery"
        case .pointerButton: "Click"
        case .pointer: "Pointer"
        case .scroll: "Scroll"
        case .browserNavigation: "Browser"
        case .wireless: "Wireless"
        }
    }

    /// Returns the Windows brush for a firmware key style.
    ///
    /// - Parameter style: The key appearance supplied by firmware.
    /// - Returns: The style's Windows background brush.
    static func background(for style: ResolvedKeyStyle) -> SolidColorBrush {
        WindowsTheme.makeBrush(
            red: UInt8((UInt16(style.red) + 43) / 2),
            green: UInt8((UInt16(style.green) + 46) / 2),
            blue: UInt8((UInt16(style.blue) + 57) / 2)
        )
    }
}
