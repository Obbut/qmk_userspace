import KeymapCompanionCore
import UWP
import WinUI

/// A retained WinUI keymap surface that updates existing elements for layer changes.
@MainActor
final class WindowsKeymapSurface {
    /// The root drawing surface.
    let canvas: Canvas

    /// The firmware-defined layers and geometry represented by this surface.
    private let definition: KeymapDefinition

    /// The layer mask represented by retained elements.
    private var renderedLayerMask: UInt32?

    /// The retained visible switch elements.
    private var keys: [RenderedKey]

    /// The retained encoder and encoder-action elements.
    private var encoders: [RenderedEncoder]

    /// Creates and lays out a retained keyboard surface.
    ///
    /// - Parameters:
    ///   - definition: The complete renderer input.
    ///   - activeLayerMask: The initial effective layer mask.
    ///   - scale: The logical-to-device-independent-pixel scale.
    init(
        definition: KeymapDefinition,
        activeLayerMask: UInt32,
        scale: Double = 0.84
    ) {
        self.definition = definition
        let canvas = Canvas()
        canvas.width = definition.geometry.canvasWidth * scale
        canvas.height = definition.geometry.canvasHeight * scale
        self.canvas = canvas

        keys = definition.positionedKeys.map { positionedKey in
            let rendered = Self.makeKey(
                key: positionedKey.key,
                placement: positionedKey.placement,
                scale: scale
            )
            canvas.children.append(rendered.border)
            return rendered
        }
        encoders = definition.encoders.map {
            Self.makeEncoder(definition: $0, scale: scale, canvas: canvas)
        }
        update(activeLayerMask: activeLayerMask)
    }

    /// Updates legends and active-layer emphasis without rebuilding the visual tree.
    ///
    /// - Parameter activeLayerMask: The effective firmware layer mask.
    func update(activeLayerMask: UInt32) {
        guard renderedLayerMask != activeLayerMask else { return }
        renderedLayerMask = activeLayerMask
        let activeLayer = definition.highestActiveLayer(in: activeLayerMask)

        for index in keys.indices {
            let legend = keys[index].key.resolvedLegend(forActiveLayerMask: activeLayerMask)
            let isDirectlyMapped = keys[index].key.isDirectlyMapped(on: activeLayer)
            if keys[index].legend != legend {
                keys[index].legend = legend
                keys[index].label.text = Self.displayText(for: legend)
                keys[index].border.background = Self.background(for: legend.style)
                try? AutomationProperties.setName(
                    keys[index].border,
                    legend.label.isEmpty ? "Unassigned key" : legend.label
                )
            }
            if keys[index].isDirectlyMapped != isDirectlyMapped {
                keys[index].isDirectlyMapped = isDirectlyMapped
                keys[index].border.borderBrush = WindowsTheme.makeBrush(
                    red: 255,
                    green: 255,
                    blue: 255,
                    alpha: isDirectlyMapped ? 48 : 26
                )
                keys[index].border.opacity = isDirectlyMapped ? 1 : 0.68
            }
        }

        for index in encoders.indices {
            var encoder = encoders[index]
            updateEncoder(
                &encoder,
                activeLayerMask: activeLayerMask,
                activeLayer: activeLayer
            )
            encoders[index] = encoder
        }
    }

    /// Updates the retained encoder labels and active-layer emphasis.
    ///
    /// - Parameters:
    ///   - activeLayerMask: The effective firmware layer mask.
    ///   - activeLayer: The highest active firmware layer.
    private func updateEncoder(
        _ encoder: inout RenderedEncoder,
        activeLayerMask: UInt32,
        activeLayer: KeymapLayer
    ) {
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

    /// Updates one retained encoder-action label and active-layer emphasis.
    ///
    /// - Parameters:
    ///   - action: The retained encoder action to update.
    ///   - activeLayerMask: The effective firmware layer mask.
    ///   - activeLayer: The highest active firmware layer.
    private func updateEncoderAction(
        _ action: inout RenderedEncoderAction,
        activeLayerMask: UInt32,
        activeLayer: KeymapLayer
    ) {
        let legend = action.key.resolvedLegend(forActiveLayerMask: activeLayerMask)
        let isDirectlyMapped = action.key.isDirectlyMapped(on: activeLayer)
        if action.legend != legend {
            action.legend = legend
            action.label.text = "\(action.arrow) \(Self.displayText(for: legend))"
            try? AutomationProperties.setName(action.border, "Encoder turn: \(legend.label)")
        }
        if action.isDirectlyMapped != isDirectlyMapped {
            action.isDirectlyMapped = isDirectlyMapped
            action.border.opacity = isDirectlyMapped ? 1 : 0.68
        }
    }
}
