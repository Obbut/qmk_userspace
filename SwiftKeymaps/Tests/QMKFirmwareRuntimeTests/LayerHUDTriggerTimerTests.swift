@testable import QMKFirmwareRuntime
import XCTest

final class LayerHUDTriggerTimerTests: XCTestCase {
    func testEligibleLayerTriggersAfterRevealDelay() {
        var timer = makeTimer(eligibleLayers: [2])

        timer.observe(layerStateMask: 1 << 2, at: 100)

        XCTAssertFalse(timer.takeTriggerIfReady(at: 3_099))
        XCTAssertTrue(timer.takeTriggerIfReady(at: 3_100))
        XCTAssertFalse(timer.takeTriggerIfReady(at: 9_000))
    }

    func testKeyDownRestartsArmedRevealDelay() {
        var timer = makeTimer(eligibleLayers: [2])
        timer.observe(layerStateMask: 1 << 2, at: 100)

        timer.recordKeyDown(at: 2_000)

        XCTAssertFalse(timer.takeTriggerIfReady(at: 4_999))
        XCTAssertTrue(timer.takeTriggerIfReady(at: 5_000))
    }

    func testNoneligibleHighestLayerDoesNotTrigger() {
        var timer = makeTimer(eligibleLayers: [2])

        timer.observe(layerStateMask: (1 << 2) | (1 << 5), at: 0)

        XCTAssertFalse(timer.takeTriggerIfReady(at: 10_000))
    }

    func testLayerChangeRearmsAfterTrigger() {
        var timer = makeTimer(eligibleLayers: [2, 3])
        timer.observe(layerStateMask: 1 << 2, at: 0)
        XCTAssertTrue(timer.takeTriggerIfReady(at: 3_000))

        timer.recordKeyDown(at: 4_000)
        XCTAssertFalse(timer.takeTriggerIfReady(at: 8_000))

        timer.observe(layerStateMask: 1 << 3, at: 8_000)
        XCTAssertFalse(timer.takeTriggerIfReady(at: 10_999))
        XCTAssertTrue(timer.takeTriggerIfReady(at: 11_000))
    }

    func testLeavingEligibleLayersCancelsReveal() {
        var timer = makeTimer(eligibleLayers: [2])
        timer.observe(layerStateMask: 1 << 2, at: 0)

        timer.observe(layerStateMask: 0, at: 2_000)

        XCTAssertFalse(timer.takeTriggerIfReady(at: 10_000))
    }

    func testRevealDelayHandlesTimestampWraparound() {
        var timer = makeTimer(eligibleLayers: [2])
        let activationTimestamp = UInt32.max - 1_000
        timer.observe(layerStateMask: 1 << 2, at: activationTimestamp)

        XCTAssertFalse(timer.takeTriggerIfReady(at: 1_998))
        XCTAssertTrue(timer.takeTriggerIfReady(at: 1_999))
    }

    /// Creates a configured timer for the listed HUD-eligible layer ordinals.
    private func makeTimer(eligibleLayers: [UInt32]) -> LayerHUDTriggerTimer {
        var timer = LayerHUDTriggerTimer()
        let mask = eligibleLayers.reduce(into: UInt32.zero) { result, layer in
            result |= UInt32(1) << layer
        }
        timer.configure(eligibleLayerMask: mask)
        return timer
    }
}
