#if DEBUG
import CWindowsShell
import Dispatch
import Foundation
import KeymapCompanionCore
import WinSDK

/// Headless regression probe for the Swift-main-executor/Win32-loop bridge.
/// It is compiled out of release builds and never creates or activates a window.
enum RunLoopPerformanceProbe {
    static var shouldRun: Bool {
        CommandLine.arguments.contains("--run-loop-probe")
    }

    static func start() {
        let mainThreadID = GetCurrentThreadId()
        let resultPath = ProcessInfo.processInfo.environment["KEYMAP_PERFORMANCE_RESULT"]
            ?? FileManager.default.temporaryDirectory
                .appendingPathComponent("KeymapCompanion-run-loop-probe.json")
                .path
        let legacy = CommandLine.arguments.contains("--legacy-run-loop-probe")

        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(50)) {
            let enqueuedAt = DispatchTime.now().uptimeNanoseconds
            DispatchQueue.main.async {
                let completedAt = DispatchTime.now().uptimeNanoseconds
                let latencyMilliseconds = Double(completedAt - enqueuedAt) / 1_000_000
                let rendering = MainActor.assumeIsolated {
                    measureRendering()
                }
                let result: [String: Any] = [
                    "mode": legacy ? "legacy-infinite-wait" : "bounded-8ms-wait",
                    "mainQueueWakeLatencyMilliseconds": latencyMilliseconds,
                    "fullRendererRebuildAverageMilliseconds": rendering.rebuildAverage,
                    "retainedRendererUpdateAverageMilliseconds": rendering.updateAverage,
                    "rendererSpeedup": rendering.rebuildAverage / rendering.updateAverage
                ]
                if let data = try? JSONSerialization.data(
                    withJSONObject: result,
                    options: [.prettyPrinted, .sortedKeys]
                ) {
                    try? data.write(to: URL(fileURLWithPath: resultPath), options: .atomic)
                }
                keymap_quit_application()
            }
        }

        // The legacy loop has no Swift-executor wake handle. This is only a
        // watchdog so that the regression measurement terminates instead of
        // sleeping forever; the fixed loop finishes long before it fires.
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(1_500)) {
            _ = PostThreadMessageW(mainThreadID, UINT(WM_NULL), 0, 0)
        }
    }

    @MainActor
    private static func measureRendering() -> (rebuildAverage: Double, updateAverage: Double) {
        let definition = KeymapDefinition.preview(for: .elora)
        let baseMask = UInt32(1) << UInt32(KeymapLayer.base.rawValue)
        let lowerMask = baseMask | (UInt32(1) << UInt32(KeymapLayer.lower.rawValue))

        let rebuildIterations = 20
        let rebuildStarted = DispatchTime.now().uptimeNanoseconds
        for index in 0..<rebuildIterations {
            _ = WindowsKeymapSurface(
                definition: definition,
                activeLayerMask: index.isMultiple(of: 2) ? baseMask : lowerMask
            ).canvas
        }
        let rebuildElapsed = DispatchTime.now().uptimeNanoseconds - rebuildStarted

        let surface = WindowsKeymapSurface(
            definition: definition,
            activeLayerMask: baseMask
        )
        let updateIterations = 200
        let updateStarted = DispatchTime.now().uptimeNanoseconds
        for index in 0..<updateIterations {
            surface.update(activeLayerMask: index.isMultiple(of: 2) ? lowerMask : baseMask)
        }
        let updateElapsed = DispatchTime.now().uptimeNanoseconds - updateStarted

        return (
            Double(rebuildElapsed) / 1_000_000 / Double(rebuildIterations),
            Double(updateElapsed) / 1_000_000 / Double(updateIterations)
        )
    }
}
#endif
