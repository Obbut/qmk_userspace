import AppKit
import SwiftUI

/// A compact, adaptive menu-bar glyph shaped like the connected split keyboard.
struct MenuBarKeyboardIcon: View {
    /// The physical keyboard whose left half is represented.
    let keyboardKind: KeyboardKind

    /// The active layer, shown in a trailing badge when it is not the base layer.
    let activeLayer: KeymapLayer

    /// Supplies the status item with an AppKit-backed template image.
    var body: some View {
        Image(
            nsImage: MenuBarKeyboardIconRenderer.makeTemplateImage(
                keyboardKind: keyboardKind,
                activeLayer: activeLayer
            )
        )
        .renderingMode(.template)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(keyboardKind.localizedDisplayName))
        .accessibilityValue(Text(activeLayer.localizedDisplayName))
    }
}

/// The SwiftUI artwork rasterized into a template image for the status item.
private struct MenuBarKeyboardArtwork: View {
    /// The physical keyboard whose left half is represented.
    let keyboardKind: KeyboardKind

    /// The active layer, shown in a trailing badge when it is not the base layer.
    let activeLayer: KeymapLayer

    /// Draws opaque artwork on a transparent background for template masking.
    var body: some View {
        Canvas { context, size in
            MenuBarKeyboardIconRenderer.draw(
                keyboardKind: keyboardKind,
                activeLayer: activeLayer,
                in: &context,
                size: size
            )
        }
        .frame(width: 34, height: 18)
        .foregroundStyle(.black)
    }
}

/// Renders the keyboard plate, keycap cutouts, and layer badge into a SwiftUI canvas.
private enum MenuBarKeyboardIconRenderer {
    /// The logical point size of the status-item image.
    private static let iconSize = CGSize(width: 34, height: 18)

    /// The design-space width of one half of either keyboard layout.
    private static let halfDesignWidth = 476.0

    /// The maximum height reserved for the keyboard silhouette.
    private static let maximumBoardHeight = 16.0

    /// The square keycap cutout size in the keymap's design space.
    private static let keycapSize = 32.0

    /// The size of the compact layer badge.
    private static let badgeSize = CGSize(width: 10, height: 8)

    /// Rasterizes the artwork and marks it as an adaptive AppKit template image.
    /// - Parameters:
    ///   - keyboardKind: The keyboard model to represent.
    ///   - activeLayer: The layer to mark in the badge.
    /// - Returns: A menu-bar-compatible template image.
    static func makeTemplateImage(
        keyboardKind: KeyboardKind,
        activeLayer: KeymapLayer
    ) -> NSImage {
        let renderer = ImageRenderer(
            content: MenuBarKeyboardArtwork(
                keyboardKind: keyboardKind,
                activeLayer: activeLayer
            )
        )
        renderer.scale = 2

        guard let image = renderer.nsImage else {
            let fallbackImage =
                NSImage(
                    systemSymbolName: "keyboard",
                    accessibilityDescription: nil
                ) ?? NSImage(size: iconSize)
            fallbackImage.isTemplate = true
            return fallbackImage
        }

        image.isTemplate = true
        return image
    }

    /// Draws the complete icon.
    /// - Parameters:
    ///   - keyboardKind: The keyboard model to represent.
    ///   - activeLayer: The layer to mark in the badge.
    ///   - context: The graphics context receiving the icon.
    ///   - size: The available menu-bar icon size.
    static func draw(
        keyboardKind: KeyboardKind,
        activeLayer: KeymapLayer,
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        let geometry = KeyboardGeometryCatalog.geometry(for: keyboardKind)
        let scale = maximumBoardHeight / geometry.canvasHeight
        let boardSize = CGSize(
            width: halfDesignWidth * scale,
            height: geometry.canvasHeight * scale
        )
        let badgeInset = boardSize.width * 0.22
        let showsLayerBadge = activeLayer != .base
        let boardRect = CGRect(
            x: (size.width - boardSize.width) / 2,
            y: (size.height - boardSize.height) / 2,
            width: boardSize.width,
            height: boardSize.height
        )

        context.fill(
            platePath(for: keyboardKind, in: boardRect),
            with: .foreground
        )
        cutOutKeycaps(
            geometry.placements,
            scale: scale,
            boardRect: boardRect,
            in: &context
        )

        if showsLayerBadge {
            let badgeRect = CGRect(
                x: boardRect.maxX - badgeInset,
                y: boardRect.maxY - badgeSize.height,
                width: badgeSize.width,
                height: badgeSize.height
            )
            context.fill(
                Path(roundedRect: badgeRect, cornerRadius: 2.1),
                with: .foreground
            )
            cutOutLayerMark(activeLayer, in: badgeRect, context: &context)
        }
    }

    /// Erases the left-half keycaps from the filled keyboard plate.
    /// - Parameters:
    ///   - placements: Every physical key placement in the full split layout.
    ///   - scale: The conversion from keymap design points to icon points.
    ///   - boardRect: The destination plate rectangle.
    ///   - context: The graphics context containing the filled plate.
    private static func cutOutKeycaps(
        _ placements: [PhysicalKeyPlacement],
        scale: Double,
        boardRect: CGRect,
        in context: inout GraphicsContext
    ) {
        context.blendMode = .destinationOut
        let renderedKeycapSize = keycapSize * scale

        for placement in placements where placement.centerX < halfDesignWidth {
            let center = CGPoint(
                x: boardRect.minX + placement.centerX * scale,
                y: boardRect.minY + placement.centerY * scale
            )
            let keycapRect = CGRect(
                x: -renderedKeycapSize / 2,
                y: -renderedKeycapSize / 2,
                width: renderedKeycapSize,
                height: renderedKeycapSize
            )
            var transform = CGAffineTransform(
                rotationAngle: placement.rotationDegrees * .pi / 180
            )
            transform.tx = center.x
            transform.ty = center.y
            let keycapPath = Path(
                roundedRect: keycapRect,
                cornerRadius: renderedKeycapSize * 0.22
            )
            .applying(transform)
            context.fill(keycapPath, with: .color(.white))
        }

        context.blendMode = .normal
    }

    /// Erases the active layer's compact symbol from the badge.
    /// - Parameters:
    ///   - activeLayer: The layer whose symbol is required.
    ///   - badgeRect: The filled badge rectangle.
    ///   - context: The graphics context containing the badge.
    private static func cutOutLayerMark(
        _ activeLayer: KeymapLayer,
        in badgeRect: CGRect,
        context: inout GraphicsContext
    ) {
        context.blendMode = .destinationOut

        switch activeLayer {
        case .lower:
            cutOutArrow(pointingUp: false, in: badgeRect, context: &context)
        case .raise:
            cutOutArrow(pointingUp: true, in: badgeRect, context: &context)
        case .base:
            return
        case .qwerty:
            cutOutText("Q", in: badgeRect, context: &context)
        case .function:
            cutOutText("FN", in: badgeRect, context: &context)
        }

        context.blendMode = .normal
    }

    /// Erases an upward or downward arrow from a layer badge.
    /// - Parameters:
    ///   - pointingUp: Whether the arrow should represent Raise instead of Lower.
    ///   - badgeRect: The badge containing the arrow.
    ///   - context: The graphics context containing the badge.
    private static func cutOutArrow(
        pointingUp: Bool,
        in badgeRect: CGRect,
        context: inout GraphicsContext
    ) {
        let centerX = badgeRect.midX
        let tipY = pointingUp ? badgeRect.minY + 2 : badgeRect.maxY - 2
        let tailY = pointingUp ? badgeRect.maxY - 2 : badgeRect.minY + 2
        let shoulderY = pointingUp ? badgeRect.minY + 4.2 : badgeRect.maxY - 4.2
        var arrow = Path()
        arrow.move(to: CGPoint(x: centerX, y: tailY))
        arrow.addLine(to: CGPoint(x: centerX, y: tipY))
        arrow.move(to: CGPoint(x: centerX - 2.1, y: shoulderY))
        arrow.addLine(to: CGPoint(x: centerX, y: tipY))
        arrow.addLine(to: CGPoint(x: centerX + 2.1, y: shoulderY))
        context.stroke(
            arrow,
            with: .color(.white),
            style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round)
        )
    }

    /// Erases a short text abbreviation from a layer badge.
    /// - Parameters:
    ///   - text: The layer abbreviation.
    ///   - badgeRect: The badge containing the text.
    ///   - context: The graphics context containing the badge.
    private static func cutOutText(
        _ text: String,
        in badgeRect: CGRect,
        context: inout GraphicsContext
    ) {
        var resolvedText = context.resolve(
            Text(verbatim: text)
                .font(.system(size: text.count == 1 ? 5.8 : 4.8, weight: .black, design: .rounded))
        )
        resolvedText.shading = .color(.white)
        context.draw(resolvedText, at: CGPoint(x: badgeRect.midX, y: badgeRect.midY), anchor: .center)
    }

    /// Builds the normalized physical plate outline for a keyboard half.
    /// - Parameters:
    ///   - keyboardKind: The keyboard model whose outline is required.
    ///   - rect: The destination rectangle.
    /// - Returns: A closed plate silhouette.
    private static func platePath(for keyboardKind: KeyboardKind, in rect: CGRect) -> Path {
        let points =
            switch keyboardKind {
            case .kyria:
                kyriaOutline
            case .elora:
                eloraOutline
            }
        var path = Path()
        guard let firstPoint = points.first else { return path }

        path.move(to: scaled(firstPoint, in: rect))
        for point in points.dropFirst() {
            path.addLine(to: scaled(point, in: rect))
        }
        path.closeSubpath()
        return path
    }

    /// Converts a normalized DXF point into the canvas's top-down coordinate space.
    /// - Parameters:
    ///   - point: A point whose axes range from zero through one.
    ///   - rect: The destination rectangle.
    /// - Returns: The scaled destination point.
    private static func scaled(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + point.x * rect.width,
            y: rect.maxY - point.y * rect.height
        )
    }

    /*
     Normalized and simplified adaptations of SplitKB's Kyria Rev4 and Elora Rev2
     bottom-plate DXFs from the Halcyon repository. Curves are reduced to straight
     segments for an 18-point menu-bar glyph. Source material is licensed CC BY-NC-SA 4.0.
     https://github.com/splitkb/halcyon/tree/main/Case%20files
     */

    /// The normalized left-half Kyria Rev4 plate outline.
    private static let kyriaOutline = [
        CGPoint(x: 0.838089, y: 0.466948),
        CGPoint(x: 0.958037, y: 0.324547),
        CGPoint(x: 1.000000, y: 0.262254),
        CGPoint(x: 1.000000, y: 0.249174),
        CGPoint(x: 0.832148, y: 0.000000),
        CGPoint(x: 0.823337, y: 0.000000),
        CGPoint(x: 0.781373, y: 0.062293),
        CGPoint(x: 0.467038, y: 0.255576),
        CGPoint(x: 0.289004, y: 0.255576),
        CGPoint(x: 0.282773, y: 0.264825),
        CGPoint(x: 0.282773, y: 0.316340),
        CGPoint(x: 0.276543, y: 0.325589),
        CGPoint(x: 0.006230, y: 0.325589),
        CGPoint(x: 0.000000, y: 0.334838),
        CGPoint(x: 0.000000, y: 0.867149),
        CGPoint(x: 0.003279, y: 0.875294),
        CGPoint(x: 0.112040, y: 0.949802),
        CGPoint(x: 0.133968, y: 0.962024),
        CGPoint(x: 0.718410, y: 1.000000),
        CGPoint(x: 0.723040, y: 0.991061),
        CGPoint(x: 0.723040, y: 0.954297),
        CGPoint(x: 0.729271, y: 0.945048),
        CGPoint(x: 0.828957, y: 0.945048),
        CGPoint(x: 0.835188, y: 0.935799),
        CGPoint(x: 0.835188, y: 0.474765),
    ]

    /// The normalized left-half Elora Rev2 plate outline.
    private static let eloraOutline = [
        CGPoint(x: 0.836351, y: 0.798653),
        CGPoint(x: 0.842578, y: 0.790823),
        CGPoint(x: 0.842578, y: 0.399603),
        CGPoint(x: 0.845452, y: 0.393006),
        CGPoint(x: 0.969806, y: 0.265510),
        CGPoint(x: 0.969849, y: 0.265461),
        CGPoint(x: 1.000000, y: 0.227552),
        CGPoint(x: 1.000000, y: 0.198762),
        CGPoint(x: 0.841915, y: 0.000000),
        CGPoint(x: 0.819016, y: 0.000000),
        CGPoint(x: 0.781917, y: 0.046645),
        CGPoint(x: 0.469931, y: 0.209126),
        CGPoint(x: 0.298831, y: 0.209126),
        CGPoint(x: 0.282640, y: 0.229483),
        CGPoint(x: 0.282640, y: 0.249605),
        CGPoint(x: 0.267694, y: 0.268396),
        CGPoint(x: 0.016191, y: 0.268396),
        CGPoint(x: 0.000000, y: 0.288754),
        CGPoint(x: 0.000000, y: 0.890109),
        CGPoint(x: 0.009405, y: 0.908592),
        CGPoint(x: 0.718436, y: 1.000000),
        CGPoint(x: 0.730484, y: 0.980933),
        CGPoint(x: 0.730484, y: 0.806483),
        CGPoint(x: 0.736711, y: 0.798653),
    ]
}

#Preview("Menu Bar Keyboard Icons") {
    HStack(spacing: 14) {
        ForEach(KeymapLayer.allCases) { layer in
            VStack(spacing: 4) {
                MenuBarKeyboardIcon(keyboardKind: .kyria, activeLayer: layer)
                Text(layer.localizedDisplayName)
                    .font(.caption2)
            }
        }
    }
    .padding()
}

#Preview("Keyboard Icon Models") {
    HStack(spacing: 28) {
        MenuBarKeyboardIcon(keyboardKind: .kyria, activeLayer: .raise)
            .scaleEffect(4)
            .frame(width: 145, height: 90)
        MenuBarKeyboardIcon(keyboardKind: .elora, activeLayer: .function)
            .scaleEffect(4)
            .frame(width: 145, height: 90)
    }
    .frame(width: 360, height: 120)
    .padding()
}
