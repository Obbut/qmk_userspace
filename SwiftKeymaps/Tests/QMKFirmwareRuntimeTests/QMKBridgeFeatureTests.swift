import QMKFirmwareRuntime
import QMKKeymapKit
import Testing

/// Host token implemented by custom Embedded Swift housekeeping code.
private let exampleHousekeeping = QMKToken("example_housekeeping")

/// Host token implemented by custom Embedded Swift record-processing code.
private let exampleProcessRecord = QMKToken("example_process_record")

/// Verifies labeled bridge arguments produce typed hook metadata.
@Test
func qmkBridgeFeatureBuildsTypedHooks() {
    let feature = QMKBridgeFeature(
        id: "example.custom-swift",
        housekeeping: exampleHousekeeping,
        processRecord: exampleProcessRecord
    )

    #expect(feature.firmwareFeatureDescriptor.id == "example.custom-swift")
    #expect(
        feature.firmwareFeatureDescriptor.embeddedSwiftHooks == [
            EmbeddedSwiftHook(callback: .housekeeping, symbol: "example_housekeeping"),
            EmbeddedSwiftHook(callback: .processRecord, symbol: "example_process_record"),
        ]
    )
}
