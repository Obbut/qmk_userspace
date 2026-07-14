@testable import KeymapCompanionCore

/// Deterministic firmware keymaps used by shared-model tests.
enum TestKeymaps {
    /// Creates a dimensionally valid Kyria keymap.
    ///
    /// - Returns: An unassigned keymap with every supported layer and encoder direction.
    static func makeKyria() -> FirmwareKeymap {
        let layerCount = KeymapLayer.allCases.count
        let rowCount = 10
        let columnCount = 7
        let matrixEntryCount = layerCount * rowCount * columnCount
        let encoderEntryCount = layerCount * EncoderDirection.allCases.count
        return FirmwareKeymap(
            keyboardKind: .kyria,
            layerCount: layerCount,
            matrixRowCount: rowCount,
            matrixColumnCount: columnCount,
            encoderCount: 1,
            fingerprint: 0,
            entries: Array(
                repeating: FirmwareKeymapEntry(keycode: 0, semantic: .none, style: .standard),
                count: matrixEntryCount + encoderEntryCount
            )
        )
    }
}
