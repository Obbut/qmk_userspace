import SwiftUI

/// The primary window that visualizes the connected keyboard's effective keymap.
struct ContentView: View {
    /// Shared process-lifetime app state.
    let model: AppModel

    /// The keymap content and native window-toolbar items.
    var body: some View {
        VStack(spacing: 20) {
            if let definition = model.keymapDefinition {
                LayerStrip(
                    activeLayer: model.activeLayer,
                    activeLayerMask: model.effectiveLayerMask
                )
                KeyboardBoardView(
                    definition: definition,
                    activeLayerMask: model.effectiveLayerMask
                )
            } else {
                ContentUnavailableView(
                    "Waiting for keyboard",
                    systemImage: "cable.connector.slash"
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .frame(minWidth: 760, minHeight: 520)
        .toolbar {
            ToolbarSpacer(.flexible)

            if model.supportsRGBSettings {
                ToolbarItem {
                    RGBSettingsPopoverButton(model: model)
                }
            }
        }
    }
}

#if DEBUG
    #Preview("Connected Elora") {
        ContentView(
            model: .makePreview(
                keyboardKind: .elora,
                activeLayers: [.raise]
            )
        )
        .frame(width: 1_180, height: 720)
    }

    #Preview("Waiting for Keyboard") {
        ContentView(
            model: .makePreview(
                connectionStatus: .searching,
                keyboardKind: nil
            )
        )
        .frame(width: 1_180, height: 720)
    }

    #Preview("Layer Strip") {
        LayerStrip(
            activeLayer: .lower,
            activeLayerMask: 0b0_0111
        )
        .padding()
        .frame(width: 520, height: 70)
    }

    #Preview("Layer Chips") {
        HStack(spacing: 12) {
            LayerChip(layer: .base, isHighest: false, isActive: true)
            LayerChip(layer: .qwerty, isHighest: false, isActive: true)
            LayerChip(layer: .lower, isHighest: true, isActive: true)
            LayerChip(layer: .raise, isHighest: false, isActive: false)
        }
        .padding()
        .frame(width: 480, height: 70)
    }
#endif

/// The stable list of supported layers and their active bits.
private struct LayerStrip: View {
    /// The highest active layer.
    let activeLayer: KeymapLayer

    /// The complete active-layer mask.
    let activeLayerMask: UInt32

    /// The layer strip content.
    var body: some View {
        HStack(spacing: 8) {
            ForEach(KeymapLayer.allCases) { layer in
                LayerChip(
                    layer: layer,
                    isHighest: layer == activeLayer,
                    isActive: layer.isActive(inLayerMask: activeLayerMask)
                )
            }
        }
        .animation(.snappy, value: activeLayer)
    }
}

/// One layer-state indicator.
private struct LayerChip: View {
    /// The represented layer.
    let layer: KeymapLayer

    /// Whether this is the layer currently rendered as primary.
    let isHighest: Bool

    /// Whether its bit is set under another active layer.
    let isActive: Bool

    /// The chip content.
    var body: some View {
        Text(layer.localizedDisplayName)
            .font(.callout.weight(isHighest ? .semibold : .regular))
            .foregroundStyle(isHighest ? Color.white : Color.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isHighest ? Color.accentColor : Color.primary.opacity(isActive ? 0.10 : 0.04), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Color.primary.opacity(isActive ? 0.18 : 0.08))
            }
    }
}
