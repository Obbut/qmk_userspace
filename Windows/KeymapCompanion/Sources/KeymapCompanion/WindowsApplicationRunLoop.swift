import Foundation
import WinSDK

/// The Win32 message loop that services WinUI and Swift's main executor.
enum WindowsApplicationRunLoop {
    /// The WinUI message pre-translation entry point.
    private typealias ContentPreTranslateMessage = @convention(c) (_ message: UnsafePointer<MSG>?) -> Bool

    /// The longest bounded wait after the Win32 queue has drained.
    ///
    /// Swift's main executor is not represented by a Win32 message-queue handle. A bounded
    /// wait ensures background HID callbacks and task wakeups reach the main actor promptly.
    private static let maximumSwiftRunLoopSleepMilliseconds = 8.0

    /// The dynamically loaded WinUI message pre-translation function.
    private static let preTranslate: ContentPreTranslateMessage? = {
        guard let module = LoadLibraryA("Microsoft.UI.Windowing.Core.dll"),
            let address = GetProcAddress(module, "ContentPreTranslateMessage")
        else {
            return nil
        }
        return unsafeBitCast(address, to: ContentPreTranslateMessage.self)
    }()

    /// Whether the diagnostic probe should reproduce the archived infinite wait.
    #if DEBUG
        private static let usesLegacyWait = CommandLine.arguments.contains("--legacy-run-loop-probe")
    #else
        private static let usesLegacyWait = false
    #endif

    /// Runs Win32 dispatch and bounded Swift main-run-loop servicing until process exit.
    ///
    /// - Returns: The exit code carried by `WM_QUIT`.
    static func run() -> Int32 {
        var message = MSG()
        while true {
            while PeekMessageW(&message, nil, 0, 0, UINT(PM_REMOVE)) {
                if message.message == UINT(WM_QUIT) {
                    return Int32(message.wParam)
                }
                if preTranslate?(&message) != true {
                    TranslateMessage(&message)
                    DispatchMessageW(&message)
                }
            }

            var nextDate: Date?
            repeat {
                nextDate = RunLoop.main.limitDate(forMode: .default)
            } while nextDate.map { $0.timeIntervalSinceNow <= 0 } ?? false

            let timeout: DWORD
            if usesLegacyWait {
                timeout =
                    nextDate.map {
                        DWORD(
                            max(
                                1,
                                min(
                                    $0.timeIntervalSinceNow * 1_000,
                                    Double(DWORD.max - 1)
                                )
                            ).rounded(.up))
                    } ?? DWORD(INFINITE)
            } else {
                let scheduledMilliseconds =
                    nextDate.map {
                        max(1, $0.timeIntervalSinceNow * 1_000)
                    } ?? maximumSwiftRunLoopSleepMilliseconds
                timeout = DWORD(
                    min(
                        scheduledMilliseconds,
                        maximumSwiftRunLoopSleepMilliseconds
                    ).rounded(.up))
            }
            _ = MsgWaitForMultipleObjects(0, nil, false, timeout, QS_ALLINPUT)
        }
    }
}
