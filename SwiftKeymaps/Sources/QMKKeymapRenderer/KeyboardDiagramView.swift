#if canImport(SwiftUI)
import SwiftUI

/// Scaled keyboard geometry used by the public production renderer.
struct KeyboardDiagramView: View {
    let document: KeymapRenderDocument

    let selectedLayerID: UInt8

    var body: some View {
        GeometryReader { proxy in
            let scale = min(
                proxy.size.width / document.canvasWidth,
                proxy.size.height / document.canvasHeight
            )
            let layerIndex = document.layers.firstIndex { $0.id == selectedLayerID } ?? 0
            diagram(layerIndex: layerIndex, scale: scale)
        }
    }

    /// Lays out every key and encoder at the supplied canvas scale.
    private func diagram(layerIndex: Int, scale: CGFloat) -> some View {
        ZStack {
            ForEach(document.keys) { key in
                let legend = key.legends.indices.contains(layerIndex)
                    ? key.legends[layerIndex]
                    : KeymapRenderLegend(label: "")
                KeymapKeyCell(
                    legend: legend,
                    width: 50 * key.placement.width * scale,
                    height: 50 * key.placement.height * scale
                )
                    .rotationEffect(.degrees(key.placement.rotationDegrees))
                    .position(
                        x: key.placement.centerX * scale,
                        y: key.placement.centerY * scale
                    )
            }

            ForEach(document.encoders) { encoder in
                let legend = encoder.pressLegends.indices.contains(layerIndex)
                    ? encoder.pressLegends[layerIndex]
                    : KeymapRenderLegend(label: "")
                KeymapEncoderCell(legend: legend)
                    .frame(width: 50 * scale, height: 50 * scale)
                    .position(
                        x: encoder.placement.centerX * scale,
                        y: encoder.placement.centerY * scale
                    )
            }
        }
        .frame(
            width: document.canvasWidth * scale,
            height: document.canvasHeight * scale,
            alignment: .topLeading
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

fileprivate struct KeymapKeyCell: View {
    let legend: KeymapRenderLegend

    let width: CGFloat

    let height: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        Group {
            if !legend.isTransparent, !legend.label.isEmpty {
                GlassEffectContainer(spacing: 0) {
                    shape
                        .fill(legend.style.color.opacity(0.08))
                        .frame(width: width, height: height)
                        .glassEffect(
                            .regular.tint(legend.style.color.opacity(0.34)),
                            in: shape
                        )
                        .overlay {
                            shape.strokeBorder(legend.style.keyBorderColor, lineWidth: 1)
                        }
                }
            } else {
                shape
                    .fill(
                        legend.style.color.opacity(legend.isTransparent ? 0.16 : 0.72)
                    )
                    .frame(width: width, height: height)
                    .overlay {
                        shape.strokeBorder(
                            legend.isTransparent
                                ? Color.primary.opacity(0.08)
                                : legend.style.keyBorderColor,
                            lineWidth: 1
                        )
                    }
            }
        }
        .overlay {
            Text(legend.label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    legend.isTransparent
                        ? Color.primary.opacity(0.35)
                        : legend.style.keyLabelColor
                )
                .lineLimit(2)
                .minimumScaleFactor(0.55)
                .multilineTextAlignment(.center)
                .padding(3)
        }
    }
}

fileprivate struct KeymapEncoderCell: View {
    let legend: KeymapRenderLegend

    var body: some View {
        Circle()
            .fill(.black.opacity(0.78))
            .stroke(legend.style.color.opacity(0.9), lineWidth: 2)
            .overlay {
                Text(legend.label)
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .padding(4)
            }
    }
}

fileprivate extension KeymapRenderStyle {
    /// The SwiftUI equivalent of the protocol RGB color.
    var color: Color {
        Color(
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255
        )
    }

    /// A high-contrast label color selected from the key's relative luminance.
    var keyLabelColor: Color {
        prefersDarkForeground ? .black.opacity(0.92) : .white
    }

    /// A subtle edge color that remains visible against the key fill.
    var keyBorderColor: Color {
        prefersDarkForeground ? .black.opacity(0.18) : .white.opacity(0.3)
    }

    /// Whether black produces better WCAG contrast than white for this RGB value.
    private var prefersDarkForeground: Bool {
        relativeLuminance > 0.179
    }

    /// WCAG relative luminance after converting the key color from sRGB.
    private var relativeLuminance: Double {
        0.2126 * linearComponent(red)
            + 0.7152 * linearComponent(green)
            + 0.0722 * linearComponent(blue)
    }

    /// Converts one 8-bit sRGB component to linear light.
    private func linearComponent(_ component: UInt8) -> Double {
        let value = Double(component) / 255
        return value <= 0.04045
            ? value / 12.92
            : pow((value + 0.055) / 1.055, 2.4)
    }
}
#endif
