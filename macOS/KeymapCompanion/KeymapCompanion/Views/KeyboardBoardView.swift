import SwiftUI

/// A scrollable visualization using the board's real switch centers and rotations.
struct KeyboardBoardView: View {
    /// The connected keyboard model.
    let keyboardKind: KeyboardKind

    /// The complete active-layer mask.
    let activeLayerMask: UInt32

    /// The physically positioned board content.
    var body: some View {
        let definition = KeymapCatalog.definition(for: keyboardKind)
        let activeLayer = KeymapLayer.highestActiveLayer(in: activeLayerMask)

        GeometryReader { viewport in
            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .topLeading) {
                    ForEach(definition.positionedKeys) { positionedKey in
                        KeyCap(
                            key: positionedKey.key,
                            activeLayer: activeLayer,
                            activeLayerMask: activeLayerMask
                        )
                        .rotationEffect(
                            .degrees(positionedKey.placement.rotationDegrees)
                        )
                        .position(
                            x: CGFloat(positionedKey.placement.centerX),
                            y: CGFloat(positionedKey.placement.centerY)
                        )
                    }
                }
                .frame(
                    width: CGFloat(definition.geometry.canvasWidth),
                    height: CGFloat(definition.geometry.canvasHeight)
                )
                .padding(20)
                .frame(
                    minWidth: viewport.size.width,
                    minHeight: viewport.size.height
                )
            }
        }
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08))
        }
    }
}

#if DEBUG
#Preview("Elora Physical Raise Board") {
    KeyboardBoardView(
        keyboardKind: .elora,
        activeLayerMask: 0b0_1001
    )
    .padding()
    .frame(width: 1_180, height: 460)
}

#Preview("Kyria Physical Lower over QWERTY Board") {
    KeyboardBoardView(
        keyboardKind: .kyria,
        activeLayerMask: 0b0_0111
    )
    .padding()
    .frame(width: 1_180, height: 405)
}

#Preview("Key Cap States") {
    HStack(spacing: 16) {
        KeyCap(
            key: KeymapCatalog.kyria.rows[0].leftKeys[1],
            activeLayer: .raise,
            activeLayerMask: 0b0_1001
        )
        KeyCap(
            key: KeymapCatalog.kyria.rows[0].leftKeys[3],
            activeLayer: .lower,
            activeLayerMask: 0b0_0111
        )
    }
    .padding()
    .frame(width: 260, height: 90)
}
#endif

/// One physical key cap with resolved transparency and RGB-inspired emphasis.
private struct KeyCap: View {
    /// The key and its layer mappings.
    let key: KeymapKey

    /// The highest active layer.
    let activeLayer: KeymapLayer

    /// The complete active-layer mask.
    let activeLayerMask: UInt32

    /// The key-cap content.
    var body: some View {
        let legend = key.resolvedLegend(activeLayerMask: activeLayerMask)
        let isDirectMapping = key.isDirectlyMapped(on: activeLayer)
        let accent = isDirectMapping ? legend.style.color : Color.secondary

        Text(verbatim: legend.label)
            .font(.callout.weight(isDirectMapping ? .semibold : .regular))
            .foregroundStyle(
                legend.label.isEmpty
                    ? Color.secondary.opacity(0.35)
                    : Color.primary
            )
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .frame(width: 52, height: 52)
            .background(
                accent.opacity(isDirectMapping ? 0.16 : 0.05),
                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(
                        accent.opacity(isDirectMapping ? 0.78 : 0.16),
                        lineWidth: isDirectMapping ? 1.5 : 1
                    )
            }
            .shadow(
                color: Color.black.opacity(isDirectMapping ? 0.10 : 0.03),
                radius: 2,
                y: 1
            )
            .animation(.snappy(duration: 0.16), value: activeLayerMask)
            .accessibilityLabel(
                legend.label.isEmpty ? "Unassigned key" : legend.label
            )
    }
}
