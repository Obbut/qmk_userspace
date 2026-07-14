import SwiftUI

/// A compact glass keymap card hosted inside the nonactivating HUD panel.
struct LayerHUDView: View {
    /// The downloaded physical keymap to render.
    let definition: KeymapDefinition

    /// The current layer snapshot.
    let presentation: LayerHUDPresentation

    /// The layer heading and scale-to-fit keyboard diagram.
    var body: some View {
        VStack(spacing: 12) {
            LayerHUDHeader(layer: presentation.layer)

            KeyboardBoardView(
                definition: definition,
                activeLayerMask: presentation.activeLayerMask,
                scalesToFit: true
            )
        }
        .padding(18)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.14))
        }
        .accessibilityElement(children: .contain)
    }
}

/// The compact active-layer heading above the HUD keyboard.
fileprivate struct LayerHUDHeader: View {
    /// The current layer represented below.
    let layer: KeymapLayer

    /// A centered layer label that stays visually subordinate to the keymap.
    var body: some View {
        Label {
            Text(layer.displayName)
        } icon: {
            Image(systemName: "square.3.layers.3d.top.filled")
        }
        .font(.headline)
        .foregroundStyle(.primary)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color.accentColor.opacity(0.16), in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(Color.accentColor.opacity(0.36))
        }
    }
}

#if DEBUG
#Preview("Lower Layer HUD") {
    LayerHUDView(
        definition: .preview(for: .elora),
        presentation: LayerHUDPresentation(
            layer: .lower,
            activeLayerMask: 0b0_0101
        )
    )
    .frame(width: 900, height: 420)
    .background(Color.gray.opacity(0.25))
}
#endif
