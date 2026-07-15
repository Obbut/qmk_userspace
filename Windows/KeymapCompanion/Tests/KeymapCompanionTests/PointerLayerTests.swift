import KeymapCompanionCore
import Testing

/// Verifies Windows accepts both legacy and pointer-enabled Kyria downloads.
@Test
func windowsSupportsFiveAndSixLayerKeymaps() throws {
    let legacy = try #require(KeymapDefinition(firmwareKeymap: makeKyriaKeymap(layerCount: 5)))
    let current = try #require(KeymapDefinition(firmwareKeymap: makeKyriaKeymap(layerCount: 6)))

    #expect(legacy.supportedLayers == [.base, .qwerty, .lower, .raise, .function])
    #expect(current.supportedLayers == KeymapLayer.allCases)
}

/// Verifies pointer protocol semantics resolve to readable Windows legends.
@Test
func windowsResolvesPointerSemanticLabels() {
    let transparent = FirmwareKeymapEntry(keycode: 0x0001, semantic: .none, style: .standard)
    let dragLock = FirmwareKeymapEntry(keycode: 0x7E02, semantic: .pointerDragLock, style: .red)
    let key = KeymapKey(
        id: "pointer-drag-lock",
        entries: [transparent, transparent, transparent, transparent, transparent, dragLock]
    )
    let pointerMask = UInt32(1 << KeymapLayer.pointer.rawValue) | 1

    #expect(key.resolvedLegend(forActiveLayerMask: pointerMask).label == "Drag Lock")
    #expect(KeymapLayer.pointer.displayName == "Pointer")
    #expect(KeymapLayer.pointer.legendName == "P")
}

/// Verifies automatic Pointer activity does not present the Windows layer HUD.
@MainActor
@Test
func windowsSuppressesPointerHUD() async throws {
    let hud = LayerHUDModel(transitionDelay: .milliseconds(20))
    let pointerMask = UInt32(1 << KeymapLayer.pointer.rawValue) | 1

    hud.update(activeLayer: .pointer, activeLayerMask: pointerMask)
    try await Task.sleep(for: .milliseconds(80))

    #expect(hud.presentation == nil)
}

/// Creates an empty Kyria firmware keymap with the requested layer count.
///
/// - Parameter layerCount: The number of matrix and encoder layers to include.
/// - Returns: A dimensionally valid Kyria keymap.
private func makeKyriaKeymap(layerCount: Int) -> FirmwareKeymap {
    let rowCount = 10
    let columnCount = 7
    let matrixEntryCount = layerCount * rowCount * columnCount
    let encoderEntryCount = layerCount * EncoderDirection.allCases.count
    let entry = FirmwareKeymapEntry(keycode: 0x0000, semantic: .none, style: .standard)

    return FirmwareKeymap(
        keyboardKind: .kyria,
        layerCount: layerCount,
        matrixRowCount: rowCount,
        matrixColumnCount: columnCount,
        encoderCount: 1,
        fingerprint: 0,
        entries: Array(repeating: entry, count: matrixEntryCount + encoderEntryCount)
    )
}
