import Testing
@testable import KeymapCompanion

/// Verifies that a transparent Lower key falls through to a toggled QWERTY layer.
@Test
func transparentKeyResolvesThroughActiveLayerStack() throws {
    let definition = KeymapCatalog.kyria
    let topRow = try #require(definition.rows.first { $0.id == "alpha-top" })
    let fPosition = try #require(topRow.leftKeys.first { $0.id == "a1-l3" })
    let qwertyAndLowerMask = UInt32(1 << KeymapLayer.base.rawValue)
        | UInt32(1 << KeymapLayer.qwerty.rawValue)
        | UInt32(1 << KeymapLayer.lower.rawValue)

    #expect(fPosition.resolvedLegend(activeLayerMask: qwertyAndLowerMask).label == "E")
    #expect(!fPosition.isDirectlyMapped(on: .lower))
}

/// Verifies that direct Raise mappings win over every lower active layer.
@Test
func directRaiseMappingWins() throws {
    let definition = KeymapCatalog.elora
    let homeRow = try #require(definition.rows.first { $0.id == "alpha-home" })
    let numberPosition = try #require(homeRow.rightKeys.first { $0.id == "a2-r1" })
    let activeMask = UInt32(1 << KeymapLayer.base.rawValue)
        | UInt32(1 << KeymapLayer.qwerty.rawValue)
        | UInt32(1 << KeymapLayer.raise.rawValue)

    let legend = numberPosition.resolvedLegend(activeLayerMask: activeMask)
    #expect(legend.label == "4")
    #expect(legend.style == .blue)
    #expect(numberPosition.isDirectlyMapped(on: .raise))
}

/// Verifies the catalog adds only the Elora number row.
@Test
func keyboardCatalogsUseDistinctPhysicalRows() {
    #expect(KeymapCatalog.kyria.rows.count == 4)
    #expect(KeymapCatalog.elora.rows.count == 5)
    #expect(KeymapCatalog.elora.rows.first?.id == "numbers")
}

/// Verifies that every logical key has one stable physical position.
@Test
func everyLogicalKeyHasAUniquePhysicalPosition() {
    let kyria = KeymapCatalog.kyria
    let elora = KeymapCatalog.elora

    #expect(kyria.positionedKeys.count == 50)
    #expect(elora.positionedKeys.count == 62)
    #expect(Set(kyria.positionedKeys.map(\.id)).count == 50)
    #expect(Set(elora.positionedKeys.map(\.id)).count == 62)
}

/// Verifies representative stagger and thumb coordinates against the README SVGs.
@Test
func physicalGeometryMatchesReadmeRenders() throws {
    let kyria = KeymapCatalog.kyria
    let elora = KeymapCatalog.elora
    let kyriaIndex = Dictionary(uniqueKeysWithValues: kyria.positionedKeys.map {
        ($0.id, $0.placement)
    })
    let eloraIndex = Dictionary(uniqueKeysWithValues: elora.positionedKeys.map {
        ($0.id, $0.placement)
    })

    let outerTop = try #require(kyriaIndex["a1-l0"])
    let middleTop = try #require(kyriaIndex["a1-l3"])
    #expect(outerTop.centerY == 70)
    #expect(middleTop.centerY == 28)

    let innerKey = try #require(kyriaIndex["a3-l7"])
    #expect(innerKey.centerX == 429)
    #expect(innerKey.centerY == 239)
    #expect(innerKey.rotationDegrees == 45)

    let innerThumb = try #require(kyriaIndex["t-l4"])
    #expect(innerThumb.centerX == 389)
    #expect(innerThumb.centerY == 278)
    #expect(innerThumb.rotationDegrees == 45)

    let eloraNumberKey = try #require(eloraIndex["n-l3"])
    let eloraAlphaKey = try #require(eloraIndex["a1-l3"])
    #expect(eloraNumberKey.centerY == 28)
    #expect(eloraAlphaKey.centerY == 84)
}
