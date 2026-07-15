import AppKit
import SwiftUI

/// A compact menu-bar glyph derived from the connected Swift layout descriptor.
struct MenuBarKeyboardIcon: View {
    /// The connected layout.
    let layoutID: LayoutID

    /// The active firmware-defined layer.
    let activeLayer: KeymapLayer

    /// Supplies the status item with an adaptive AppKit template image.
    var body: some View {
        Image(
            nsImage: MenuBarKeyboardIconRenderer.makeTemplateImage(
                layoutID: layoutID,
                activeLayer: activeLayer
            )
        )
        .renderingMode(.template)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(layoutID.localizedDisplayName))
        .accessibilityValue(Text(activeLayer.localizedDisplayName))
    }
}

/// SwiftUI artwork rasterized into a template image for the status item.
fileprivate struct MenuBarKeyboardArtwork: View {
    /// The catalog-backed keyboard definition.
    let definition: KeymapDefinition

    /// The active layer shown in the badge.
    let activeLayer: KeymapLayer

    /// Draws opaque artwork on a transparent background for template masking.
    var body: some View {
        Canvas { context, size in
            MenuBarKeyboardIconRenderer.draw(
                definition: definition,
                activeLayer: activeLayer,
                in: &context,
                size: size
            )
        }
        .frame(width: 34, height: 18)
        .foregroundStyle(.black)
    }
}

/// Renders dynamic layout geometry and the active-layer badge.
fileprivate enum MenuBarKeyboardIconRenderer {
    /// The logical point size of the status-item image.
    static let iconSize = CGSize(width: 34, height: 18)

    /// Rasterizes catalog-backed artwork as an adaptive template image.
    static func makeTemplateImage(layoutID: LayoutID, activeLayer: KeymapLayer) -> NSImage {
        let definition = KeymapDefinition.makePreview(for: layoutID)
        let renderer = ImageRenderer(
            content: MenuBarKeyboardArtwork(definition: definition, activeLayer: activeLayer)
        )
        renderer.scale = 2
        guard let image = renderer.nsImage else { return fallbackImage }
        image.isTemplate = true
        return image
    }

    /// Draws the complete dynamic icon.
    static func draw(
        definition: KeymapDefinition,
        activeLayer: KeymapLayer,
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        let badgeWidth = activeLayer.rawValue == 0 ? 0.0 : 10.0
        let availableWidth = size.width - badgeWidth
        let scale = min(
            availableWidth / definition.geometry.canvasWidth,
            size.height / definition.geometry.canvasHeight
        )
        let boardSize = CGSize(
            width: definition.geometry.canvasWidth * scale,
            height: definition.geometry.canvasHeight * scale
        )
        let boardRect = CGRect(
            x: 0,
            y: (size.height - boardSize.height) / 2,
            width: boardSize.width,
            height: boardSize.height
        )
        context.fill(Path(roundedRect: boardRect, cornerRadius: 2.2), with: .foreground)

        context.blendMode = .destinationOut
        for placement in definition.geometry.placements {
            let keyRect = CGRect(
                x: boardRect.minX + (placement.centerX - 20 * placement.width) * scale,
                y: boardRect.minY + (placement.centerY - 20 * placement.height) * scale,
                width: 40 * placement.width * scale,
                height: 40 * placement.height * scale
            )
            context.fill(Path(roundedRect: keyRect, cornerRadius: max(0.4, 4 * scale)), with: .color(.white))
        }
        context.blendMode = .normal

        if activeLayer.rawValue != 0 {
            let badgeRect = CGRect(x: size.width - 9, y: 5, width: 9, height: 8)
            context.fill(Path(roundedRect: badgeRect, cornerRadius: 2), with: .foreground)
            context.blendMode = .destinationOut
            var text = context.resolve(
                Text(verbatim: activeLayer.legendName.uppercased())
                    .font(.system(size: 4.8, weight: .black, design: .rounded))
            )
            text.shading = .color(.white)
            context.draw(text, at: CGPoint(x: badgeRect.midX, y: badgeRect.midY), anchor: .center)
            context.blendMode = .normal
        }
    }

    /// A generic keyboard symbol used before catalog metadata is available.
    static var fallbackImage: NSImage {
        let image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)
            ?? NSImage(size: iconSize)
        image.isTemplate = true
        return image
    }
}

#if DEBUG
#Preview("Catalog Menu Bar Icons") {
    HStack(spacing: 22) {
        ForEach([LayoutID.kyria, .elora, .q15, .planck], id: \.rawValue) { layoutID in
            let definition = KeymapDefinition.makePreview(for: layoutID)
            if let layer = definition.supportedLayers.last {
                VStack {
                    MenuBarKeyboardIcon(layoutID: layoutID, activeLayer: layer)
                        .scaleEffect(4)
                        .frame(width: 140, height: 80)
                    Text(layoutID.displayName)
                }
            }
        }
    }
    .padding()
}
#endif
