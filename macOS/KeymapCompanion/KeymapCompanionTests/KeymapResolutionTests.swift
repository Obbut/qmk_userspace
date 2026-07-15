import Testing
@testable import KeymapCompanion

/// Verifies all four firmware modules produce production renderer input.
@Test
func everyFirmwareProducesACompleteRenderDefinition() {
    let expectedKeyCounts: [LayoutID: Int] = [
        .kyria: 50,
        .elora: 62,
        .q15: 66,
        .planck: 47,
    ]

    for (layoutID, expectedKeyCount) in expectedKeyCounts {
        let definition = KeymapDefinition.makePreview(for: layoutID)
        #expect(definition.positionedKeys.count == expectedKeyCount)
        #expect(Set(definition.positionedKeys.map(\.id)).count == expectedKeyCount)
        #expect(!definition.supportedLayers.isEmpty)
        #expect(definition.semanticCatalogMatches)
        #expect(definition.styleCatalogMatches)
    }
}

/// Verifies transparent mappings fall through the authored active-layer stack.
@Test
func transparentMappingsResolveThroughActiveLayers() throws {
    let definition = KeymapDefinition.makePreview(for: .kyria)
    let lower = try #require(definition.supportedLayers.first { $0.displayName == "Lower" })
    let mask = UInt32(1 << lower.rawValue) | 1

    #expect(
        definition.positionedKeys.contains {
            !$0.key.isDirectlyMapped(on: lower)
                && !$0.key.resolvedLegend(forActiveLayerMask: mask).label.isEmpty
        }
    )
}

/// Verifies the Kyria pointer layer resolves domain-owned semantic presentation.
@Test
func pointerSemanticsProduceReadableLegends() throws {
    let definition = KeymapDefinition.makePreview(for: .kyria)
    let pointer = try #require(
        definition.supportedLayers.first { $0.displayName == "Pointer" }
    )
    let mask = UInt32(1 << pointer.rawValue) | 1
    let legends = definition.positionedKeys.map {
        $0.key.resolvedLegend(forActiveLayerMask: mask).label
    }

    #expect(legends.contains("Drag Lock"))
    #expect(legends.contains("Sniper"))
}

/// Verifies layout descriptors expose exact physical switch and encoder geometry.
@Test
func layoutGeometryAndEncodersComeFromSwiftDescriptors() {
    let kyria = KeymapDefinition.makePreview(for: .kyria)
    let elora = KeymapDefinition.makePreview(for: .elora)
    let q15 = KeymapDefinition.makePreview(for: .q15)
    let planck = KeymapDefinition.makePreview(for: .planck)

    #expect(kyria.geometry.canvasWidth > 0)
    #expect(elora.geometry.canvasHeight > kyria.geometry.canvasHeight)
    #expect(kyria.encoders.count == 1)
    #expect(elora.encoders.count == 1)
    #expect(q15.encoders.count == 2)
    #expect(planck.encoders.isEmpty)
}
