import SwiftUI

/// A scrollable visualization using the board's real switch centers and rotations.
struct KeyboardBoardView: View {
    /// The visual definition downloaded from the connected firmware.
    let definition: KeymapDefinition

    /// The complete active-layer mask.
    let activeLayerMask: UInt32

    /// Whether the complete keyboard should shrink to the available viewport.
    let scalesToFit: Bool

    /// Creates a physical keymap visualization.
    /// - Parameters:
    ///   - definition: The downloaded visual keymap.
    ///   - activeLayerMask: The complete active-layer mask.
    ///   - scalesToFit: Whether to shrink the complete keyboard instead of scrolling it.
    init(
        definition: KeymapDefinition,
        activeLayerMask: UInt32,
        scalesToFit: Bool = false
    ) {
        self.definition = definition
        self.activeLayerMask = activeLayerMask
        self.scalesToFit = scalesToFit
    }

    /// The physically positioned board content.
    var body: some View {
        GeometryReader { viewport in
            let canvasWidth = CGFloat(definition.geometry.canvasWidth)
            let canvasHeight = CGFloat(definition.geometry.canvasHeight)
            let paddedWidth = canvasWidth + 40
            let paddedHeight = canvasHeight + 40

            if scalesToFit {
                let scale = min(
                    1,
                    viewport.size.width / paddedWidth,
                    viewport.size.height / paddedHeight
                )

                KeyboardDiagramView(
                    definition: definition,
                    activeLayerMask: activeLayerMask
                )
                .frame(
                    width: canvasWidth,
                    height: canvasHeight
                )
                .padding(20)
                .scaleEffect(scale)
                .frame(
                    width: viewport.size.width,
                    height: viewport.size.height
                )
            } else {
                ScrollView([.horizontal, .vertical]) {
                    KeyboardDiagramView(
                        definition: definition,
                        activeLayerMask: activeLayerMask
                    )
                    .frame(width: canvasWidth, height: canvasHeight)
                    .padding(20)
                    .frame(
                        minWidth: viewport.size.width,
                        minHeight: viewport.size.height
                    )
                }
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

/// The keyboard and encoder positioned inside the board's fixed coordinate space.
fileprivate struct KeyboardDiagramView: View {
    /// The downloaded visual keymap.
    let definition: KeymapDefinition

    /// The complete active-layer mask.
    let activeLayerMask: UInt32

    /// Every physical key and the right encoder.
    var body: some View {
        let activeLayer = KeymapLayer.highestActiveLayer(in: activeLayerMask)

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

            KeyboardEncoderView(
                encoder: definition.rightEncoder,
                activeLayer: activeLayer,
                activeLayerMask: activeLayerMask
            )
            .frame(
                width: CGFloat(definition.geometry.canvasWidth),
                height: CGFloat(definition.geometry.canvasHeight)
            )
        }
    }
}

#if DEBUG
#Preview("Elora Physical Raise Board") {
    KeyboardBoardView(
        definition: .preview(for: .elora),
        activeLayerMask: 0b0_1001
    )
    .padding()
    .frame(width: 1_180, height: 460)
}

#Preview("Kyria Physical Lower over QWERTY Board") {
    KeyboardBoardView(
        definition: .preview(for: .kyria),
        activeLayerMask: 0b0_0111
    )
    .padding()
    .frame(width: 1_180, height: 405)
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
        let font = Font.callout.weight(isDirectMapping ? .semibold : .regular)

        Group {
            if let systemImageName = legend.systemImageName {
                Image(systemName: systemImageName)
                    .symbolRenderingMode(.monochrome)
            } else {
                Text(verbatim: legend.label)
            }
        }
        .font(font)
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
        .help(
            LocalizedStringResource(
                "Firmware matrix position: \(key.id)",
                comment: "Tooltip for a keycap; the value is its firmware row-and-column identifier."
            )
        )
    }
}

#if DEBUG
#Preview("Native Apple Key Glyphs") {
    let keycodes: [UInt16] = [
        0x00E0, 0x00E2, 0x00E3, 0x00E1, 0x0029, 0x002B, 0x0004,
        0x002A, 0x0028, 0x002C, 0x0039, 0x004C, 0x0080, 0x003A
    ]
    let keys = keycodes.map { keycode in
        let entry = FirmwareKeymapEntry(
            keycode: keycode,
            semantic: 0,
            style: .standard
        )
        return KeymapKey(
            id: "\(keycode)",
            entries: Array(
                repeating: entry,
                count: KeymapLayer.allCases.count
            )
        )
    }

    Grid(horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
            ForEach(keys.prefix(7)) { key in
                KeyCap(
                    key: key,
                    activeLayer: .base,
                    activeLayerMask: 1
                )
            }
        }

        GridRow {
            ForEach(keys.suffix(7)) { key in
                KeyCap(
                    key: key,
                    activeLayer: .base,
                    activeLayerMask: 1
                )
            }
        }
    }
    .padding()
}
#endif
