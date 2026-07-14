import Foundation
import WinSDK

/// Corrects the fractional-timeout bug in the archived SwiftApplication sample
/// loop while preserving WinUI keyboard/pointer message pre-translation.
enum WindowsApplicationRunLoop {
    private typealias ContentPreTranslateMessage = @convention(c) (UnsafePointer<MSG>?) -> Bool

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
            if let nextDate {
                let milliseconds = max(1, min(nextDate.timeIntervalSinceNow * 1_000, Double(DWORD.max - 1)))
                timeout = DWORD(milliseconds.rounded(.up))
            } else {
                timeout = DWORD(INFINITE)
            }
            _ = MsgWaitForMultipleObjects(0, nil, false, timeout, QS_ALLINPUT)
        }
    }
}
