import WinAppSDK
import WinUI

/// The WinUI application lifecycle for Keymap Companion.
///
/// Swift/WinRT invokes lifecycle callbacks on the UI thread; each callback explicitly
/// enters the main actor before accessing ``controller``.
@main
final class KeymapCompanionWindowsApp: SwiftApplication, @unchecked Sendable {
    /// The native presentation controller retained for the process lifetime.
    private var controller: WindowsAppController?

    /// Creates the Swift/WinRT application delegate.
    required init() {
        super.init()
    }

    /// The Windows message-loop integration used by Swift/WinRT.
    override class var runLoop: RunLoop {
        { _ in WindowsApplicationRunLoop.run() }
    }

    /// Creates and launches the native presentation after WinUI activation.
    ///
    /// Debug performance-probe launches start their headless measurements instead.
    ///
    /// - Parameter activationArguments: The WinUI launch arguments.
    override func onLaunched(_ activationArguments: WinUI.LaunchActivatedEventArgs) {
        MainActor.assumeIsolated {
            #if DEBUG
                if RunLoopPerformanceProbe.shouldRun {
                    RunLoopPerformanceProbe.start()
                    return
                }
            #endif
            let controller = WindowsAppController()
            self.controller = controller
            controller.launch()
        }
    }

    /// Releases app-owned resources during Swift/WinRT shutdown.
    ///
    /// - Parameter exitCode: The process exit code selected by WinUI.
    override func onShutdown(exitCode: Int32) {
        MainActor.assumeIsolated {
            controller?.shutdown()
        }
    }
}
