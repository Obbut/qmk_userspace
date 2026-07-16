import ObbutKeyboardCatalog
@testable import KeymapCompanionCore

/// Deterministic firmware keymaps used by shared-model tests.
enum TestKeymaps {
    /// Creates a valid Kyria keymap with configurable generated metadata.
    static func makeKyria(
        legendFingerprint: UInt32? = nil,
        styleFingerprint: UInt32? = nil,
        legendID: LegendID = .none,
        styleID: StyleID = .standard
    ) -> FirmwareKeymap {
        guard let firmware = ObbutKeyboardCatalog.firmware(named: "kyria") else {
            preconditionFailure("The test catalog must contain Kyria firmware.")
        }
        let layerCount = firmware.layers.count
        let matrixEntryCount =
            layerCount * firmware.layout.matrixRowCount * firmware.layout.matrixColumnCount
        let encoderEntryCount = layerCount * firmware.layout.encoders.count * 2
        return FirmwareKeymap(
            layoutID: .kyria,
            layerCount: layerCount,
            matrixRowCount: firmware.layout.matrixRowCount,
            matrixColumnCount: firmware.layout.matrixColumnCount,
            encoderCount: firmware.layout.encoders.count,
            fingerprint: 0,
            legendFingerprint: legendFingerprint
                ?? firmware.legendFingerprint,
            styleFingerprint: styleFingerprint
                ?? firmware.styleFingerprint,
            entries: Array(
                repeating: FirmwareKeymapEntry(
                    keycode: 0,
                    legendID: legendID,
                    styleID: styleID
                ),
                count: matrixEntryCount + encoderEntryCount
            )
        )
    }
}
