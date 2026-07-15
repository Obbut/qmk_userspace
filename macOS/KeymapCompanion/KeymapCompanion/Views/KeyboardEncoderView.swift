import SwiftUI

/// The right encoder rendered in the board coordinate space with all three actions visible.
struct KeyboardEncoderView: View {
    /// The physical encoder and its layer mappings.
    let encoder: KeymapEncoder

    /// The highest active layer.
    let activeLayer: KeymapLayer

    /// The complete active-layer mask.
    let activeLayerMask: UInt32

    /// The encoder, directional annotations, and their connectors.
    var body: some View {
        let centerX = CGFloat(encoder.placement.centerX)
        let centerY = CGFloat(encoder.placement.centerY)
        let pressLegend = encoder.pressKey.resolvedLegend(
            forActiveLayerMask: activeLayerMask
        )

        ZStack(alignment: .topLeading) {
            Path { path in
                path.move(to: CGPoint(x: centerX - 118, y: centerY - 37))
                path.addCurve(
                    to: CGPoint(x: centerX - 25, y: centerY - 17),
                    control1: CGPoint(x: centerX - 83, y: centerY - 34),
                    control2: CGPoint(x: centerX - 44, y: centerY - 29)
                )

                path.move(to: CGPoint(x: centerX - 39, y: centerY - 37))
                path.addCurve(
                    to: CGPoint(x: centerX - 5, y: centerY - 29),
                    control1: CGPoint(x: centerX - 26, y: centerY - 36),
                    control2: CGPoint(x: centerX - 13, y: centerY - 33)
                )

                path.move(to: CGPoint(x: centerX - 58, y: centerY + 38))
                path.addCurve(
                    to: CGPoint(x: centerX - 26, y: centerY + 17),
                    control1: CGPoint(x: centerX - 46, y: centerY + 36),
                    control2: CGPoint(x: centerX - 33, y: centerY + 27)
                )
            }
            .stroke(
                Color.secondary.opacity(0.35),
                style: StrokeStyle(lineWidth: 1, lineCap: .round)
            )

            EncoderActionView(
                direction: LocalizedStringResource(
                    "CCW",
                    comment: "Label for turning a keyboard encoder counter-clockwise."
                ),
                directionSystemImageName: "arrow.counterclockwise",
                key: encoder.counterclockwiseKey,
                activeLayer: activeLayer,
                activeLayerMask: activeLayerMask
            )
            .position(x: centerX - 160, y: centerY - 58)

            EncoderActionView(
                direction: LocalizedStringResource(
                    "CW",
                    comment: "Label for turning a keyboard encoder clockwise."
                ),
                directionSystemImageName: "arrow.clockwise",
                key: encoder.clockwiseKey,
                activeLayer: activeLayer,
                activeLayerMask: activeLayerMask
            )
            .position(x: centerX - 60, y: centerY - 58)

            EncoderActionView(
                direction: LocalizedStringResource(
                    "PRESS",
                    comment: "Label for pressing a keyboard encoder."
                ),
                directionSystemImageName: "arrow.up",
                key: encoder.pressKey,
                activeLayer: activeLayer,
                activeLayerMask: activeLayerMask
            )
            .position(x: centerX - 100, y: centerY + 55)

            EncoderKnobView(pressLegend: pressLegend)
                .position(x: centerX, y: centerY)
        }
        .animation(.snappy(duration: 0.16), value: activeLayerMask)
        .accessibilityElement(children: .contain)
        .help(
            LocalizedStringResource(
                "Firmware encoder: right; press position: \(encoder.pressKey.id)",
                comment: "Tooltip for the right encoder; the value is the firmware matrix position of its push switch."
            )
        )
    }
}

/// The circular physical control with the current push action in its center.
fileprivate struct EncoderKnobView: View {
    /// The effective firmware action for pressing the encoder.
    let pressLegend: KeyLegend

    /// The knob rendering without an artificial position indicator.
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.14))

            Circle()
                .strokeBorder(Color.accentColor.opacity(0.72), lineWidth: 1.5)

            Circle()
                .inset(by: 5)
                .trim(from: 0.025, to: 0.975)
                .stroke(
                    Color.primary.opacity(0.30),
                    style: StrokeStyle(
                        lineWidth: 2,
                        lineCap: .round,
                        dash: [1, 4]
                    )
                )
                .rotationEffect(.degrees(-90))

            Circle()
                .fill(.regularMaterial)
                .frame(width: 36, height: 36)
                .overlay {
                    Group {
                        if let systemImageName = pressLegend.systemImageName {
                            Image(systemName: systemImageName)
                        } else if pressLegend.label.isEmpty {
                            Image(systemName: "circle.dashed")
                                .foregroundStyle(.secondary)
                        } else {
                            Text(verbatim: pressLegend.encoderDisplayLabel)
                        }
                    }
                    .font(.callout.weight(.semibold))
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                    .padding(5)
                }
        }
        .frame(width: 58, height: 58)
        .shadow(color: Color.black.opacity(0.11), radius: 3, y: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            pressLegend.label.isEmpty
                ? Text("Unassigned encoder press", comment: "Accessibility label for an encoder with no push action.")
                : Text(
                    "Encoder press: \(pressLegend.label)",
                    comment: "Accessibility label for the encoder push action; the value is the firmware key name."
                )
        )
    }
}

/// One always-visible encoder interaction and its effective firmware action.
fileprivate struct EncoderActionView: View {
    /// The localized physical interaction name.
    let direction: LocalizedStringResource

    /// The SF Symbol describing the physical interaction.
    let directionSystemImageName: String

    /// The action mapped to this interaction across every layer.
    let key: KeymapKey

    /// The highest active layer.
    let activeLayer: KeymapLayer

    /// The complete active-layer mask.
    let activeLayerMask: UInt32

    /// The two-line physical interaction and action label.
    var body: some View {
        let legend = key.resolvedLegend(forActiveLayerMask: activeLayerMask)
        let isDirectMapping = key.isDirectlyMapped(on: activeLayer)

        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: directionSystemImageName)
                Text(direction)
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)

            HStack(spacing: 5) {
                if let systemImageName = legend.systemImageName {
                    Image(systemName: systemImageName)
                }

                if legend.label.isEmpty {
                    Text(
                        "Unassigned",
                        comment: "Visible encoder action label when firmware maps no keycode."
                    )
                    .foregroundStyle(.secondary)
                } else {
                    Text(verbatim: legend.encoderDisplayLabel)
                }
            }
            .font(.caption.weight(isDirectMapping ? .semibold : .regular))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .fixedSize()
        .accessibilityElement(children: .combine)
    }
}

/// Encoder-specific legend presentation.
fileprivate extension KeyLegend {
    /// A compact encoder-specific rendering of common media actions.
    var encoderDisplayLabel: String {
        switch label {
        case "Previous Track":
            "Previous"
        case "Next Track":
            "Next"
        case "Play or Pause":
            "Play / Pause"
        default:
            label
        }
    }
}

#if DEBUG
    #Preview("Right Encoder — Lower") {
        let definition = KeymapDefinition.makePreview(for: .kyria)

        KeyboardEncoderView(
            encoder: definition.rightEncoder,
            activeLayer: .lower,
            activeLayerMask: 0b0_0101
        )
        .frame(
            width: CGFloat(definition.geometry.canvasWidth),
            height: CGFloat(definition.geometry.canvasHeight)
        )
        .padding()
    }

    #Preview("Encoder Knob") {
        let definition = KeymapDefinition.makePreview(for: .kyria)
        let legend = definition.rightEncoder.pressKey.resolvedLegend(
            forActiveLayerMask: 0b0_0101
        )

        EncoderKnobView(pressLegend: legend)
            .padding()
    }

    #Preview("Encoder Action") {
        let definition = KeymapDefinition.makePreview(for: .kyria)

        EncoderActionView(
            direction: "CCW",
            directionSystemImageName: "arrow.counterclockwise",
            key: definition.rightEncoder.counterclockwiseKey,
            activeLayer: .lower,
            activeLayerMask: 0b0_0101
        )
        .padding()
    }
#endif
