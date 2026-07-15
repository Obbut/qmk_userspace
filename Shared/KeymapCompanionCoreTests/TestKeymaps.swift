import ObbutKeyboardCatalog
@testable import KeymapCompanionCore

/// Deterministic firmware keymaps used by shared-model tests.
enum TestKeymaps {
    /// Creates a dimensionally valid Kyria keymap with configurable catalog IDs.
    static func makeKyria(
        semanticCatalogFingerprint: UInt32? = nil,
        styleCatalogFingerprint: UInt32? = nil,
        semanticID: SemanticID = .none,
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
            semanticCatalogFingerprint: semanticCatalogFingerprint
                ?? firmware.semanticCatalogFingerprint,
            styleCatalogFingerprint: styleCatalogFingerprint
                ?? firmware.styleCatalogFingerprint,
            entries: Array(
                repeating: FirmwareKeymapEntry(
                    keycode: 0,
                    semanticID: semanticID,
                    styleID: styleID
                ),
                count: matrixEntryCount + encoderEntryCount
            )
        )
    }
}
