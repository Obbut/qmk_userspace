import Testing
@testable import KeymapCompanion

/// Verifies that a transparent Lower key falls through to a toggled QWERTY layer.
@Test
func transparentKeyResolvesThroughActiveLayerStack() throws {
    let firmwareKeymap = makeFirmwareKeymap(for: .kyria) { entries, rows, columns in
        setEntry(keycode: 0x0009, layer: .base, row: 0, column: 3, in: &entries, rows: rows, columns: columns)
        setEntry(keycode: 0x0008, layer: .qwerty, row: 0, column: 3, in: &entries, rows: rows, columns: columns)
    }
    let definition = try #require(KeymapDefinition(firmwareKeymap: firmwareKeymap))
    let key = try #require(definition.positionedKeys.first { $0.id == "r0c3" }?.key)
    let qwertyAndLowerMask = UInt32(1 << KeymapLayer.base.rawValue)
        | UInt32(1 << KeymapLayer.qwerty.rawValue)
        | UInt32(1 << KeymapLayer.lower.rawValue)

    #expect(key.resolvedLegend(activeLayerMask: qwertyAndLowerMask).label == "E")
    #expect(!key.isDirectlyMapped(on: .lower))
}

/// Verifies that direct Raise mappings and their firmware styles win over lower layers.
@Test
func directRaiseMappingWins() throws {
    let firmwareKeymap = makeFirmwareKeymap(for: .elora) { entries, rows, columns in
        setEntry(
            keycode: 0x0021,
            style: .blue,
            layer: .raise,
            row: 8,
            column: 2,
            in: &entries,
            rows: rows,
            columns: columns
        )
    }
    let definition = try #require(KeymapDefinition(firmwareKeymap: firmwareKeymap))
    let key = try #require(definition.positionedKeys.first { $0.id == "r8c2" }?.key)
    let activeMask = UInt32(1 << KeymapLayer.base.rawValue)
        | UInt32(1 << KeymapLayer.qwerty.rawValue)
        | UInt32(1 << KeymapLayer.raise.rawValue)

    let legend = key.resolvedLegend(activeLayerMask: activeMask)
    #expect(legend.label == "4")
    #expect(legend.style == .blue)
    #expect(key.isDirectlyMapped(on: .raise))
}

/// Verifies firmware-only semantic annotations restore names lost during preprocessing.
@Test
func firmwareSemanticOverridesNumericKeycodeLabel() throws {
    let firmwareKeymap = makeFirmwareKeymap(for: .kyria) { entries, rows, columns in
        setEntry(
            keycode: 0x0B21,
            semantic: 1,
            layer: .base,
            row: 3,
            column: 4,
            in: &entries,
            rows: rows,
            columns: columns
        )
    }
    let definition = try #require(KeymapDefinition(firmwareKeymap: firmwareKeymap))
    let key = try #require(definition.positionedKeys.first { $0.id == "r3c4" }?.key)

    #expect(key.resolvedLegend(activeLayerMask: 1).label == "Screenshot")
}

/// Verifies that every visible switch has one unique firmware matrix coordinate.
@Test
func everyVisibleKeyHasAUniquePhysicalPosition() throws {
    let kyria = try #require(KeymapDefinition(firmwareKeymap: makeFirmwareKeymap(for: .kyria)))
    let elora = try #require(KeymapDefinition(firmwareKeymap: makeFirmwareKeymap(for: .elora)))

    #expect(kyria.positionedKeys.count == 50)
    #expect(elora.positionedKeys.count == 62)
    #expect(Set(kyria.positionedKeys.map(\.id)).count == 50)
    #expect(Set(elora.positionedKeys.map(\.id)).count == 62)
}

/// Verifies representative matrix-to-geometry mappings against the README SVGs.
@Test
func physicalGeometryMatchesReadmeRenders() throws {
    let kyria = try #require(KeymapDefinition(firmwareKeymap: makeFirmwareKeymap(for: .kyria)))
    let elora = try #require(KeymapDefinition(firmwareKeymap: makeFirmwareKeymap(for: .elora)))
    let kyriaIndex = Dictionary(uniqueKeysWithValues: kyria.positionedKeys.map {
        ($0.id, $0.placement)
    })
    let eloraIndex = Dictionary(uniqueKeysWithValues: elora.positionedKeys.map {
        ($0.id, $0.placement)
    })

    let outerTop = try #require(kyriaIndex["r0c6"])
    let middleTop = try #require(kyriaIndex["r0c3"])
    #expect(outerTop.centerY == 70)
    #expect(middleTop.centerY == 28)

    let innerKey = try #require(kyriaIndex["r2c0"])
    #expect(innerKey.centerX == 429)
    #expect(innerKey.centerY == 239)
    #expect(innerKey.rotationDegrees == 45)

    let innerThumb = try #require(kyriaIndex["r3c0"])
    #expect(innerThumb.centerX == 389)
    #expect(innerThumb.centerY == 278)
    #expect(innerThumb.rotationDegrees == 45)

    let eloraNumberKey = try #require(eloraIndex["r0c3"])
    let eloraAlphaKey = try #require(eloraIndex["r1c3"])
    #expect(eloraNumberKey.centerY == 28)
    #expect(eloraAlphaKey.centerY == 84)
}

/// Creates a dimensionally accurate firmware matrix for tests.
/// - Parameters:
///   - keyboardKind: The matrix shape to create.
///   - customize: Optional entry mutations applied before returning.
/// - Returns: A complete five-layer test keymap.
private func makeFirmwareKeymap(
    for keyboardKind: KeyboardKind,
    customize: (_ entries: inout [FirmwareKeymapEntry], _ rows: Int, _ columns: Int) -> Void = { _, _, _ in }
) -> FirmwareKeymap {
    let rows = keyboardKind == .kyria ? 10 : 12
    let columns = 7
    let transparent = FirmwareKeymapEntry(keycode: 0x0001, semantic: 0, style: .standard)
    let unassigned = FirmwareKeymapEntry(keycode: 0x0000, semantic: 0, style: .standard)
    var entries = Array(repeating: transparent, count: KeymapLayer.allCases.count * rows * columns)
    for row in 0..<rows {
        for column in 0..<columns {
            setEntry(
                unassigned,
                layer: .base,
                row: row,
                column: column,
                in: &entries,
                rows: rows,
                columns: columns
            )
        }
    }
    customize(&entries, rows, columns)
    return FirmwareKeymap(
        keyboardKind: keyboardKind,
        layerCount: KeymapLayer.allCases.count,
        matrixRowCount: rows,
        matrixColumnCount: columns,
        fingerprint: 0,
        entries: entries
    )
}

/// Replaces one layer-major matrix entry.
/// - Parameters:
///   - entry: The complete replacement entry.
///   - layer: The QMK layer.
///   - row: The matrix row.
///   - column: The matrix column.
///   - entries: The payload to mutate.
///   - rows: The matrix row count.
///   - columns: The matrix column count.
private func setEntry(
    _ entry: FirmwareKeymapEntry,
    layer: KeymapLayer,
    row: Int,
    column: Int,
    in entries: inout [FirmwareKeymapEntry],
    rows: Int,
    columns: Int
) {
    entries[Int(layer.rawValue) * rows * columns + row * columns + column] = entry
}

/// Creates and writes one keycode-oriented test entry.
/// - Parameters:
///   - keycode: The compiled QMK keycode.
///   - semantic: The optional firmware semantic identifier.
///   - style: The firmware visual style.
///   - layer: The QMK layer.
///   - row: The matrix row.
///   - column: The matrix column.
///   - entries: The payload to mutate.
///   - rows: The matrix row count.
///   - columns: The matrix column count.
private func setEntry(
    keycode: UInt16,
    semantic: UInt8 = 0,
    style: KeyStyle = .standard,
    layer: KeymapLayer,
    row: Int,
    column: Int,
    in entries: inout [FirmwareKeymapEntry],
    rows: Int,
    columns: Int
) {
    setEntry(
        FirmwareKeymapEntry(keycode: keycode, semantic: semantic, style: style),
        layer: layer,
        row: row,
        column: column,
        in: &entries,
        rows: rows,
        columns: columns
    )
}
