import SwiftUI

/// A single-surface glass keymap card hosted inside the nonactivating HUD panel.
struct LayerHUDView: View {
    /// The downloaded physical keymap to render.
    let definition: KeymapDefinition

    /// The current layer snapshot.
    let presentation: LayerHUDPresentation

    /// The layer heading and scale-to-fit keyboard diagram.
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            LayerHUDHeader(layer: presentation.layer)

            KeyboardBoardView(
                definition: definition,
                activeLayerMask: presentation.activeLayerMask,
                scalesToFit: true
            )
        }
        .padding(.horizontal, 22)
        .padding(.top, 16)
        .padding(.bottom, 18)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22))
        }
        .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
        .padding(8)
        .accessibilityElement(children: .contain)
    }
}

/// The understated active-layer heading above the HUD keyboard.
fileprivate struct LayerHUDHeader: View {
    /// The current layer represented below.
    let layer: KeymapLayer

    /// A leading layer label that stays visually subordinate to the keymap.
    var body: some View {
        Label {
            Text(layer.localizedDisplayName)
        } icon: {
            Image(systemName: "square.3.layers.3d.top.filled")
                .foregroundStyle(Color.accentColor)
        }
        .font(.system(size: 15, weight: .semibold, design: .rounded))
        .foregroundStyle(.primary)
        .padding(.leading, 4)
    }
}

#if DEBUG
    #Preview("Glass Keys") {
        let definition = KeymapDefinition.makePreview(for: .elora)
        let layer = definition.supportedLayers[3]
        LayerHUDView(
            definition: definition,
            presentation: LayerHUDPresentation(
                layer: layer,
                activeLayerMask: UInt32(1) << UInt32(layer.rawValue)
            )
        )
        .frame(width: 900, height: 420)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.30, blue: 0.55),
                    Color(red: 0.52, green: 0.24, blue: 0.58),
                    Color(red: 0.92, green: 0.53, blue: 0.30),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .preferredColorScheme(.light)
    }
#endif
