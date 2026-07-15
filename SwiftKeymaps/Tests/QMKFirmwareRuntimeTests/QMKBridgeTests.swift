import QMKFirmwareRuntime
import QMKKeymapKit
import Testing

/// Host token captured by `#qmkBridge` and implemented only in Embedded Swift.
private let example_housekeeping = QMKToken("example_housekeeping")

/// Host token captured by `#qmkBridge` and implemented only in Embedded Swift.
private let example_process_record = QMKToken("example_process_record")

/// Verifies `#qmkBridge` captures undeclared C symbols as typed hook metadata.
@Test
func qmkBridgeBuildsTypedHooks() {
    let feature: QMKBridgeFeature = #qmkBridge(
        id: "example.custom-swift",
        housekeeping: example_housekeeping,
        processRecord: example_process_record
    )

    #expect(feature.firmwareFeatureDescriptor.id == "example.custom-swift")
    #expect(
        feature.firmwareFeatureDescriptor.embeddedSwiftHooks == [
            EmbeddedSwiftHook(callback: .housekeeping, symbol: "example_housekeeping"),
            EmbeddedSwiftHook(callback: .processRecord, symbol: "example_process_record"),
        ]
    )
}
