import QMKFirmwareRuntime
import XCTest

final class RGBIndicatorRangeTests: XCTestCase {
    func testEmptyAndReversedRangesAreNotIterable() {
        XCTAssertFalse(RGBIndicatorRange(lowerBound: 4, upperBound: 8).isEmpty)
        XCTAssertTrue(RGBIndicatorRange(lowerBound: 4, upperBound: 4).isEmpty)
        XCTAssertTrue(RGBIndicatorRange(lowerBound: 8, upperBound: 4).isEmpty)
    }
}
