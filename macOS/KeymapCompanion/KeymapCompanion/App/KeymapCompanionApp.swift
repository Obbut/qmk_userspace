import SwiftUI

/// The windowed and menu-bar lifecycle for Keymap Companion.
@main
struct KeymapCompanionApp: App {
    /// Shared process-lifetime state; closing a window does not release it.
    @State private var model = AppModel()

    /// The main keymap window and persistent menu-bar extra.
    var body: some Scene {
        WindowGroup("Keymap Companion", id: "keymap") {
            ContentView(model: model)
        }
        .defaultSize(width: 1_180, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(after: .appInfo) {
                Button("Reconnect Keyboard") {
                    model.reconnect()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            if model.connectionStatus.isConnected {
                Label {
                    Text(model.activeLayer.displayName)
                } icon: {
                    Image(systemName: "keyboard.fill")
                }
            } else {
                Label("Keymap Companion", systemImage: "keyboard")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
