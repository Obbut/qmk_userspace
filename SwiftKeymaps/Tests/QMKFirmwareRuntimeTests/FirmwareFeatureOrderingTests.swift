import QMKFirmwareRuntime
import XCTest

final class FirmwareFeatureOrderingTests: XCTestCase {
    func testFeaturesRunInDeclarationOrder() {
        typealias Features = FirmwareFeatureGroup<
            FirmwareFeatureDefinition<FirstFeature>,
            FirmwareFeatureDefinition<SecondFeature>
        >
        var state = Features.initialState
        var context = FirmwareContext()

        let disposition = Features.processRecord(
            KeyEvent(keycode: 4, isPressed: true),
            state: &state,
            context: &context
        )

        XCTAssertEqual(disposition, .continueProcessing)
        XCTAssertEqual(context.layerState, 112)
        XCTAssertEqual(state.0, 1)
        XCTAssertEqual(state.1, 1)
    }

    func testRemovingAFeatureRemovesItsBehavior() {
        typealias Features = FirmwareFeatureDefinition<SecondFeature>
        var state = Features.initialState
        var context = FirmwareContext()

        _ = Features.processRecord(
            KeyEvent(keycode: 4, isPressed: true),
            state: &state,
            context: &context
        )

        XCTAssertEqual(context.layerState, 12)
        XCTAssertEqual(state, 1)
    }
}

private struct FirstFeature: FirmwareFeature {
    static let initialState = 0

    static func processRecord(
        _ event: KeyEvent,
        state: inout Int,
        context: inout FirmwareContext
    ) -> KeyEventDisposition {
        state += 1
        context.layerState = context.layerState * 10 + 1
        return .continueProcessing
    }
}

private struct SecondFeature: FirmwareFeature {
    static let initialState = 0

    static func processRecord(
        _ event: KeyEvent,
        state: inout Int,
        context: inout FirmwareContext
    ) -> KeyEventDisposition {
        state += 1
        context.layerState = context.layerState * 10 + 2
        return .continueProcessing
    }
}
