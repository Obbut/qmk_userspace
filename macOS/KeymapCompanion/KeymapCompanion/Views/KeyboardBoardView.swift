import QMKKeymapRenderer
import SwiftUI

/// A scrollable visualization backed by the shared production renderer.
struct KeyboardBoardView: View {
    /// The visual definition downloaded from connected firmware.
    let definition: KeymapDefinition

    /// The union of momentary and persistent layer masks.
    let activeLayerMask: UInt32

    /// Whether geometry scales to the viewport instead of scrolling.
    let scalesToFit: Bool

    init(
        definition: KeymapDefinition,
        activeLayerMask: UInt32,
        scalesToFit: Bool = false
    ) {
        self.definition = definition
        self.activeLayerMask = activeLayerMask
        self.scalesToFit = scalesToFit
    }

    var body: some View {
        let activeLayer = definition.highestActiveLayer(in: activeLayerMask)
        Group {
            if scalesToFit {
                renderer(activeLayerID: activeLayer.rawValue)
                    .padding(20)
            } else {
                ScrollView([.horizontal, .vertical]) {
                    renderer(activeLayerID: activeLayer.rawValue)
                        .frame(
                            width: definition.geometry.canvasWidth,
                            height: definition.geometry.canvasHeight
                        )
                        .padding(20)
                }
            }
        }
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08))
        }
    }

    private func renderer(activeLayerID: UInt8) -> some View {
        KeymapRendererView(
            document: definition.renderDocument,
            selectedLayerID: activeLayerID
        )
    }
}

#if DEBUG
#Preview("All Four Production Renderers") {
    ScrollView {
        VStack(spacing: 20) {
            ForEach([LayoutID.kyria, .elora, .q15, .planck], id: \.rawValue) { layoutID in
                let definition = KeymapDefinition.makePreview(for: layoutID)
                VStack(alignment: .leading) {
                    Text(definition.displayName).font(.headline)
                    KeyboardBoardView(definition: definition, activeLayerMask: 1, scalesToFit: true)
                        .frame(height: 260)
                }
            }
        }
        .padding()
    }
    .frame(width: 1_100, height: 760)
}
#endif
