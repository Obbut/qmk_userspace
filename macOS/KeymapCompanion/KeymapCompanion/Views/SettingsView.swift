import Observation
import ServiceManagement
import SwiftUI

/// Application preferences presented by the SwiftUI Settings scene.
struct SettingsView: View {
    /// Tracks the main app's registration as a system login item.
    @State private var loginItemSettings = LoginItemSettings()

    /// The app lifecycle phase used to refresh changes made in System Settings.
    @Environment(\.scenePhase) private var scenePhase

    /// The general application settings form.
    var body: some View {
        @Bindable var loginItemSettings = loginItemSettings

        Form {
            Section {
                Toggle("Launch at Login", isOn: $loginItemSettings.isRegistered)

                if loginItemSettings.requiresApproval {
                    LabeledContent {
                        Button("Open Login Items Settings") {
                            loginItemSettings.openSystemSettings()
                        }
                    } label: {
                        Label("Approval Required", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            } footer: {
                Text("Automatically open Keymap Companion when you log in to your Mac.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .onAppear {
            loginItemSettings.refresh()
        }
        .onChange(of: scenePhase) { _, newScenePhase in
            guard newScenePhase == .active else { return }
            loginItemSettings.refresh()
        }
        .alert(
            "Unable to Update Launch at Login",
            isPresented: $loginItemSettings.isPresentingError,
            presenting: loginItemSettings.errorMessage
        ) { _ in
            Button("OK") {}
        } message: { errorMessage in
            Text(errorMessage)
        }
    }
}

/// Bridges SwiftUI controls to the system registration for the main app login item.
@MainActor
@Observable
fileprivate final class LoginItemSettings {
    /// Whether the app is registered to launch at login, including registrations awaiting approval.
    fileprivate var isRegistered: Bool {
        get {
            status == .enabled || status == .requiresApproval
        }
        set {
            updateRegistration(to: newValue)
        }
    }

    /// Whether the user must approve the registered login item in System Settings.
    fileprivate var requiresApproval: Bool {
        status == .requiresApproval
    }

    /// Whether the most recent registration error should be presented.
    fileprivate var isPresentingError: Bool {
        get {
            errorMessage != nil
        }
        set {
            if !newValue {
                errorMessage = nil
            }
        }
    }

    /// A user-presentable description of the most recent registration failure.
    fileprivate private(set) var errorMessage: String?

    /// The system service representing the main application as a login item.
    private let service: SMAppService

    /// The most recently observed registration status.
    private var status: SMAppService.Status

    /// Creates settings backed by the supplied app service.
    /// - Parameter service: The system login service to inspect and update.
    fileprivate init(service: SMAppService = .mainApp) {
        self.service = service
        status = service.status
    }

    /// Refreshes the displayed state from the system's current registration status.
    fileprivate func refresh() {
        status = service.status
    }

    /// Opens System Settings at the Login Items panel so the user can grant approval.
    fileprivate func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    /// Registers or unregisters the main app to match the requested state.
    /// - Parameter shouldRegister: Whether the app should be registered as a login item.
    private func updateRegistration(to shouldRegister: Bool) {
        guard shouldRegister != isRegistered else { return }

        do {
            if shouldRegister {
                try service.register()
            } else {
                try service.unregister()
            }
            errorMessage = nil
        } catch {
            refresh()
            errorMessage = shouldRegister && requiresApproval
                ? nil
                : error.localizedDescription
            return
        }

        refresh()
    }
}

#if DEBUG
    #Preview("Settings") {
        SettingsView()
    }
#endif
