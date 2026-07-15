import KeymapCompanionCore
import Testing

/// Verifies every Obbut firmware definition can drive the Windows renderer.
@Test
func windowsSupportsEveryCatalogKeyboard() {
    for layoutID in [LayoutID.kyria, .elora, .q15, .planck] {
        let definition = KeymapDefinition.makePreview(for: layoutID)

        #expect(!definition.positionedKeys.isEmpty)
        #expect(!definition.supportedLayers.isEmpty)
        #expect(definition.semanticCatalogMatches)
        #expect(definition.styleCatalogMatches)
    }
}

/// Verifies the shared Obbut catalog resolves pointer semantics for Windows.
@Test
func windowsResolvesPointerSemanticLabels() throws {
    let definition = KeymapDefinition.makePreview(for: .kyria)
    let pointer = try #require(
        definition.supportedLayers.first { $0.displayName == "Pointer" }
    )
    let pointerMask = UInt32(1 << pointer.rawValue) | 1
    let legends = definition.positionedKeys.map {
        $0.key.resolvedLegend(forActiveLayerMask: pointerMask).label
    }

    #expect(legends.contains("Drag Lock"))
    #expect(pointer.legendName == "P")
}

/// Verifies automatic pointer activity does not present the Windows layer HUD.
@MainActor
@Test
func windowsSuppressesPointerHUD() async throws {
    let definition = KeymapDefinition.makePreview(for: .kyria)
    let pointer = try #require(
        definition.supportedLayers.first { $0.displayName == "Pointer" }
    )
    let hud = LayerHUDModel(transitionDelay: .milliseconds(20))
    let pointerMask = UInt32(1 << pointer.rawValue) | 1

    hud.update(activeLayer: pointer, activeLayerMask: pointerMask)
    try await Task.sleep(for: .milliseconds(80))

    #expect(hud.presentation == nil)
}
