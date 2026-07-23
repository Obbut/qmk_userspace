import Dependencies
import Foundation
import KeymapCompanionCore
import SwiftUI

/// The windowed and menu-bar lifecycle for Keymap Companion.
@main
struct KeymapCompanionApp: App {
    /// Shared process-lifetime state; closing a window does not release it.
    @State private var model: AppModel

    /// The AppKit owner that keeps the nonactivating layer HUD alive without a window scene.
    private let layerHUDController: LayerHUDController

    /// Creates shared state and its process-lifetime overlay controller together.
    init() {
        let environment = ProcessInfo.processInfo.environment
        let model: AppModel
        if environment["XCTestConfigurationFilePath"] != nil {
            model = withDependencies {
                $0.keyboardHardware = KeyboardHardwareClientKey.testValue
            } operation: {
                AppModel.makeLive()
            }
        } else {
            model = AppModel.makeLive()
        }
        _model = State(initialValue: model)
        layerHUDController = LayerHUDController(model: model)
    }

    /// The main keymap window and persistent menu-bar extra.
    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            if model.connectionStatus.isConnected, let layoutID = model.layoutID {
                MenuBarKeyboardIcon(
                    layoutID: layoutID,
                    activeLayer: model.activeLayer
                )
            } else {
                Image(systemName: "keyboard")
                    .accessibilityLabel("Keymap Companion")
            }
        }
        .menuBarExtraStyle(.menu)

        Window("Keymap Companion", id: "keymap") {
            ContentView(model: model)
        }
        .defaultSize(width: 1_180, height: 720)
        .defaultLaunchBehavior(.presented)
        .windowToolbarStyle(.unified)
        .windowToolbarLabelStyle(fixed: .iconOnly)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("Reconnect Keyboard") {
                    model.reconnect()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
}
