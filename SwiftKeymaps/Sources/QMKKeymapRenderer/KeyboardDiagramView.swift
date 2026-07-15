#if canImport(SwiftUI)
import SwiftUI

/// Scaled keyboard geometry used by the public production renderer.
struct KeyboardDiagramView: View {
    /// The complete renderer document.
    let document: KeymapRenderDocument

    /// The selected QMK layer identifier.
    let selectedLayerID: UInt8

    /// The keyboard canvas.
    var body: some View {
        GeometryReader { proxy in
            let scale = min(
                proxy.size.width / document.canvasWidth,
                proxy.size.height / document.canvasHeight
            )
            let layerIndex = document.layers.firstIndex { $0.id == selectedLayerID } ?? 0
            ZStack {
                RoundedRectangle(cornerRadius: 24 * scale)
                    .fill(.black.opacity(0.18))
                    .stroke(.white.opacity(0.08), lineWidth: max(1, scale))

                ForEach(document.keys) { key in
                    let legend = key.legends.indices.contains(layerIndex)
                        ? key.legends[layerIndex]
                        : KeymapRenderLegend(label: "")
                    KeymapKeyCell(legend: legend)
                        .frame(
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
}

/// One styled switch in the keyboard diagram.
fileprivate struct KeymapKeyCell: View {
    /// Layer-specific legend.
    let legend: KeymapRenderLegend

    /// The styled key cap.
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(legend.style.color.opacity(legend.isTransparent ? 0.16 : 0.72))
            .stroke(.white.opacity(legend.isTransparent ? 0.1 : 0.22), lineWidth: 1)
            .overlay {
                Text(legend.label)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(legend.isTransparent ? 0.35 : 0.95))
                    .lineLimit(2)
                    .minimumScaleFactor(0.55)
                    .multilineTextAlignment(.center)
                    .padding(3)
            }
    }
}

/// One physical encoder knob in the keyboard diagram.
fileprivate struct KeymapEncoderCell: View {
    /// Layer-specific press legend.
    let legend: KeymapRenderLegend

    /// The styled encoder knob.
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

/// SwiftUI conversion for domain RGB colors.
fileprivate extension KeymapRenderStyle {
    var color: Color {
        Color(
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255
        )
    }
}
#endif
