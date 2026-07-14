import SwiftUI

/// The primary window that visualizes the connected keyboard's effective keymap.
struct ContentView: View {
    /// Shared process-lifetime app state.
    let model: AppModel

    /// The composed window content.
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.10),
                    Color.clear,
                    Color.purple.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                ConnectionHeader(
                    status: model.connectionStatus,
                    keyboardKind: model.keyboardKind,
                    activeLayer: model.activeLayer
                )

                if let keyboardKind = model.keyboardKind {
                    LayerStrip(
                        activeLayer: model.activeLayer,
                        activeLayerMask: model.effectiveLayerMask
                    )
                    KeyboardBoardView(
                        keyboardKind: keyboardKind,
                        activeLayerMask: model.effectiveLayerMask
                    )
                } else {
                    WaitingPanel()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
        }
        .frame(minWidth: 760, minHeight: 520)
    }
}

#if DEBUG
#Preview("Connected Elora") {
    ContentView(
        model: .preview(
            keyboardKind: .elora,
            activeLayers: [.raise]
        )
    )
    .frame(width: 1_180, height: 720)
}

#Preview("Waiting for Keyboard") {
    ContentView(
        model: .preview(
            connectionStatus: .searching,
            keyboardKind: nil
        )
    )
    .frame(width: 1_180, height: 720)
}

#Preview("Connection Header") {
    ConnectionHeader(
        status: .connected,
        keyboardKind: .kyria,
        activeLayer: .lower
    )
    .padding()
    .frame(width: 1_000, height: 100)
}

#Preview("Status Badges") {
    HStack(spacing: 16) {
        StatusBadge(status: .searching)
        StatusBadge(status: .connected)
        StatusBadge(status: .disconnected)
        StatusBadge(status: .failed("Preview failure"))
    }
    .padding()
    .frame(width: 720, height: 80)
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

#Preview("Waiting Panel") {
    WaitingPanel()
        .padding()
        .frame(width: 760, height: 520)
}
#endif

/// The top-level device and active-layer summary.
private struct ConnectionHeader: View {
    /// The connection phase to display.
    let status: ConnectionStatus

    /// The last validated keyboard model.
    let keyboardKind: KeyboardKind?

    /// The currently effective highest layer.
    let activeLayer: KeymapLayer

    /// The header content.
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "keyboard.badge.ellipsis")
                .font(.largeTitle)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Keymap Companion")
                    .font(.title.bold())
                if let keyboardKind {
                    Text(keyboardKind.displayName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Realtime keymap")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            StatusBadge(status: status)

            if keyboardKind != nil {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("ACTIVE LAYER")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(activeLayer.displayName)
                        .font(.title2.bold())
                        .contentTransition(.numericText())
                }
            }
        }
    }
}

/// A compact connection-status capsule.
private struct StatusBadge: View {
    /// The connection phase to display.
    let status: ConnectionStatus

    /// The status capsule content.
    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusTitle)
                .font(.callout.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: Capsule())
        .help(statusDetail)
    }

    /// The localized status title.
    private var statusTitle: LocalizedStringResource {
        switch status {
        case .searching:
            "Searching"
        case .connected:
            "Connected"
        case .disconnected:
            "Disconnected"
        case .failed:
            "Connection Error"
        }
    }

    /// A localized explanation suitable for a tooltip.
    private var statusDetail: LocalizedStringResource {
        switch status {
        case .searching:
            "Looking for a compatible QMK Raw HID interface."
        case .connected:
            "Receiving realtime layer changes from the keyboard."
        case .disconnected:
            "The keyboard was disconnected; discovery remains active."
        case let .failed(message):
            "HID monitoring failed: \(message)"
        }
    }

    /// The semantic color for the current connection phase.
    private var statusColor: Color {
        switch status {
        case .searching:
            .orange
        case .connected:
            .green
        case .disconnected:
            .secondary
        case .failed:
            .red
        }
    }
}

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
                    isActive: layer.isActive(in: activeLayerMask)
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
        Text(layer.displayName)
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

/// Waiting state shown while automatic keyboard discovery remains active.
private struct WaitingPanel: View {
    /// The waiting-state content.
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cable.connector.slash")
                .font(.system(.largeTitle, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("Waiting for keyboard")
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
