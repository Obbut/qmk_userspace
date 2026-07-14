import Foundation
import WinSDK

/// Corrects the fractional-timeout bug in the archived SwiftApplication sample
/// loop while preserving WinUI keyboard/pointer message pre-translation.
enum WindowsApplicationRunLoop {
    private typealias ContentPreTranslateMessage = @convention(c) (UnsafePointer<MSG>?) -> Bool

    /// Swift's main executor is not represented by a Win32 message-queue
    /// handle. Never let the WinUI loop sleep indefinitely after draining
    /// messages, or background HID callbacks and Task wakeups can remain queued
    /// until the next mouse or keyboard event.
    private static let maximumSwiftRunLoopSleepMilliseconds = 8.0

    private static let preTranslate: ContentPreTranslateMessage? = {
        guard let module = LoadLibraryA("Microsoft.UI.Windowing.Core.dll"),
              let address = GetProcAddress(module, "ContentPreTranslateMessage") else {
            return nil
        }
        return unsafeBitCast(address, to: ContentPreTranslateMessage.self)
    }()

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
#if DEBUG
            let usesLegacyWait = CommandLine.arguments.contains("--legacy-run-loop-probe")
#else
            let usesLegacyWait = false
#endif
            if usesLegacyWait {
                timeout = nextDate.map {
                    DWORD(max(1, min(
                        $0.timeIntervalSinceNow * 1_000,
                        Double(DWORD.max - 1)
                    )).rounded(.up))
                } ?? DWORD(INFINITE)
            } else {
                let scheduledMilliseconds = nextDate.map {
                    max(1, $0.timeIntervalSinceNow * 1_000)
                } ?? maximumSwiftRunLoopSleepMilliseconds
                timeout = DWORD(min(
                    scheduledMilliseconds,
                    maximumSwiftRunLoopSleepMilliseconds
                ).rounded(.up))
            }
            _ = MsgWaitForMultipleObjects(0, nil, false, timeout, QS_ALLINPUT)
        }
    }
}
