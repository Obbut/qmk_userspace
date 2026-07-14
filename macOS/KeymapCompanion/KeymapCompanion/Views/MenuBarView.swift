import AppKit
import SwiftUI

/// The persistent menu-bar control surface for connection and window commands.
struct MenuBarView: View {
    /// Shared process-lifetime app state.
    let model: AppModel

    /// The action used to reopen the main keymap window.
    @Environment(\.openWindow) private var openWindow

    /// The menu-bar popover content.
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: model.connectionStatus.isConnected ? "keyboard.fill" : "keyboard")
                    .font(.title2)
                    .foregroundStyle(model.connectionStatus.isConnected ? Color.green : Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    if let keyboardKind = model.keyboardKind {
                        Text(keyboardKind.displayName)
                            .font(.headline)
                        Text("Layer: \(model.activeLayer.displayName)")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Searching for keyboard")
                            .font(.headline)
                        Text("Elora or Kyria with companion firmware")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            Button("Open Keymap Window", systemImage: "macwindow") {
                openWindow(id: "keymap")
                NSApplication.shared.activate()
            }
            .keyboardShortcut("o")

            Button("Reconnect Keyboard", systemImage: "arrow.clockwise") {
                model.reconnect()
            }

            Divider()

            Button("Quit Keymap Companion", systemImage: "power") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .buttonStyle(.plain)
        .padding(16)
        .frame(width: 300)
    }
}

#if DEBUG
#Preview("Connected Menu Bar") {
    MenuBarView(
        model: .preview(
            keyboardKind: .kyria,
            activeLayers: [.qwerty, .lower]
        )
    )
    .frame(height: 250)
}

#Preview("Searching Menu Bar") {
    MenuBarView(
        model: .preview(
            connectionStatus: .searching,
            keyboardKind: nil
        )
    )
    .frame(height: 250)
}
#endif
