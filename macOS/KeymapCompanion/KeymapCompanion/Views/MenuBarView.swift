import AppKit
import SwiftUI

/// Standard menu items for the persistent menu-bar extra.
struct MenuBarView: View {
    /// Shared process-lifetime app state.
    let model: AppModel

    /// The action used to reopen the main keymap window.
    @Environment(\.openWindow) private var openWindow

    /// The native menu content.
    var body: some View {
        Button(action: {}) {
            Label {
                switch model.connectionStatus {
                case .searching:
                    Text("Searching for Keyboard")
                case .connected:
                    if let layoutID = model.layoutID {
                        Text(layoutID.localizedDisplayName)
                    } else {
                        Text("Keyboard Connected")
                    }
                case .disconnected:
                    Text("Keyboard Disconnected")
                case .failed:
                    Text("Keyboard Connection Error")
                }
            } icon: {
                Image(
                    systemName: model.connectionStatus.isConnected
                        ? "keyboard.fill"
                        : "keyboard"
                )
            }
        }
        .disabled(true)

        if model.connectionStatus.isConnected {
            Button(action: {}) {
                Label {
                    Text(model.activeLayer.localizedDisplayName)
                } icon: {
                    Image(systemName: "square.3.layers.3d")
                }
            }
            .disabled(true)
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
        .keyboardShortcut("r", modifiers: [.command, .shift])

        Divider()

        SettingsLink {
            Label("Settings", systemImage: "gearshape")
        }
        .keyboardShortcut(",")

        Divider()

        Button("Quit Keymap Companion", systemImage: "power") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}

#if DEBUG
    #Preview("Connected Menu Items") {
        Menu("Keymap Companion", systemImage: "keyboard.fill") {
            MenuBarView(
                model: .makePreview(
                    layoutID: .kyria,
                    activeLayers: KeymapDefinition.makePreview(for: .kyria).supportedLayers.prefix(3).map { $0 }
                )
            )
        }
        .padding()
    }

    #Preview("Searching Menu Items") {
        Menu("Keymap Companion", systemImage: "keyboard") {
            MenuBarView(
                model: .makePreview(
                    connectionStatus: .searching,
                    layoutID: nil
                )
            )
        }
        .padding()
    }
#endif
