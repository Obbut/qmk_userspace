/// One physical key and its firmware-owned entries across all supported layers.
public struct KeymapKey: Equatable, Identifiable, Sendable {
    public let id: String
    public let entries: [FirmwareKeymapEntry]

    public init(id: String, entries: [FirmwareKeymapEntry]) {
        self.id = id
        self.entries = entries
    }

    public func resolvedLegend(activeLayerMask: UInt32) -> KeyLegend {
        for layer in KeymapLayer.allCases.reversed() where layer.isActive(in: activeLayerMask) {
            let index = Int(layer.rawValue)
            guard index < entries.count else { continue }
            let entry = entries[index]
            if entry.keycode != 0x0001 {
                return QMKKeycodeLegend.legend(for: entry)
            }
        }
        return entries.first.map(QMKKeycodeLegend.legend(for:))
            ?? KeyLegend(label: "")
    }

    public func isDirectlyMapped(on layer: KeymapLayer) -> Bool {
        let index = Int(layer.rawValue)
        return index < entries.count && entries[index].keycode != 0x0001
    }
}

/// A keymap key paired with its physical board position.
public struct PositionedKey: Equatable, Identifiable, Sendable {
    public let key: KeymapKey
    public let placement: PhysicalKeyPlacement
    public var id: String { key.id }

    public init(key: KeymapKey, placement: PhysicalKeyPlacement) {
        self.key = key
        self.placement = placement
    }
}

/// One physical encoder and its firmware-owned mappings across every layer.
public struct KeymapEncoder: Equatable, Sendable {
    public let id: String
    public let placement: PhysicalKeyPlacement
    public let counterClockwiseKey: KeymapKey
    public let pressKey: KeymapKey
    public let clockwiseKey: KeymapKey

    public init(
        id: String,
        placement: PhysicalKeyPlacement,
        counterClockwiseKey: KeymapKey,
        pressKey: KeymapKey,
        clockwiseKey: KeymapKey
    ) {
        self.id = id
        self.placement = placement
        self.counterClockwiseKey = counterClockwiseKey
        self.pressKey = pressKey
        self.clockwiseKey = clockwiseKey
    }
}

/// The complete renderer input for one supported keyboard model.
public struct KeymapDefinition: Equatable, Sendable {
    public let keyboardKind: KeyboardKind
    public let geometry: KeyboardGeometry
    public let positionedKeys: [PositionedKey]
    public let rightEncoder: KeymapEncoder

    public init?(firmwareKeymap: FirmwareKeymap) {
        let geometry = KeyboardGeometryCatalog.geometry(for: firmwareKeymap.keyboardKind)
        let matrixEntryCount = firmwareKeymap.layerCount
            * firmwareKeymap.matrixRowCount
            * firmwareKeymap.matrixColumnCount
        let encoderEntryCount = firmwareKeymap.layerCount
            * firmwareKeymap.encoderCount
            * EncoderDirection.allCases.count
        guard firmwareKeymap.layerCount == KeymapLayer.allCases.count,
              firmwareKeymap.encoderCount > 0,
              firmwareKeymap.entries.count == matrixEntryCount + encoderEntryCount,
              geometry.placements.count == geometry.matrixPositions.count,
              Set(geometry.matrixPositions).count == geometry.matrixPositions.count else {
            return nil
        }

        let keys = geometry.matrixPositions.compactMap { position -> KeymapKey? in
            let entries = KeymapLayer.allCases.compactMap { layer in
                firmwareKeymap.entry(
                    layer: Int(layer.rawValue),
                    row: position.row,
                    column: position.column
                )
            }
            guard entries.count == KeymapLayer.allCases.count else { return nil }
            return KeymapKey(id: "r\(position.row)c\(position.column)", entries: entries)
        }
        guard keys.count == geometry.placements.count else { return nil }

        let counterClockwiseEntries = KeymapLayer.allCases.compactMap { layer in
            firmwareKeymap.encoderEntry(
                layer: Int(layer.rawValue),
                encoder: 0,
                direction: .counterClockwise
            )
        }
        let clockwiseEntries = KeymapLayer.allCases.compactMap { layer in
            firmwareKeymap.encoderEntry(
                layer: Int(layer.rawValue),
                encoder: 0,
                direction: .clockwise
            )
        }
        let pressRow = firmwareKeymap.matrixRowCount - 1
        let pressEntries = KeymapLayer.allCases.compactMap { layer in
            firmwareKeymap.entry(
                layer: Int(layer.rawValue),
                row: pressRow,
                column: 0
            )
        }
        guard counterClockwiseEntries.count == KeymapLayer.allCases.count,
              pressEntries.count == KeymapLayer.allCases.count,
              clockwiseEntries.count == KeymapLayer.allCases.count else {
            return nil
        }

        keyboardKind = firmwareKeymap.keyboardKind
        self.geometry = geometry
        positionedKeys = zip(keys, geometry.placements).map {
            PositionedKey(key: $0, placement: $1)
        }
        rightEncoder = KeymapEncoder(
            id: "encoder-right",
            placement: geometry.rightEncoderPlacement,
            counterClockwiseKey: KeymapKey(
                id: "encoder-right-ccw",
                entries: counterClockwiseEntries
            ),
            pressKey: KeymapKey(
                id: "r\(pressRow)c0",
                entries: pressEntries
            ),
            clockwiseKey: KeymapKey(
                id: "encoder-right-cw",
                entries: clockwiseEntries
            )
        )
    }

#if DEBUG
    /// Creates representative renderer input without a HID device.
    public static func preview(for keyboardKind: KeyboardKind) -> KeymapDefinition {
        let layerCount = KeymapLayer.allCases.count
        let rowCount = keyboardKind == .kyria ? 10 : 12
        let columnCount = 7
        let matrixSize = rowCount * columnCount
        let transparent = FirmwareKeymapEntry(keycode: 0x0001, semantic: 0, style: .standard)
        let unassigned = FirmwareKeymapEntry(keycode: 0x0000, semantic: 0, style: .standard)
        var entries = Array(repeating: transparent, count: layerCount * matrixSize)
        entries.replaceSubrange(0..<matrixSize, with: repeatElement(unassigned, count: matrixSize))

        let rightHomeRow = keyboardKind == .kyria ? 6 : 8
        let rightHomeKeycodes: [UInt16] = [0x0010, 0x0011, 0x0008, 0x000C, 0x0012, 0x0034]
        for (columnOffset, keycode) in rightHomeKeycodes.enumerated() {
            entries[rightHomeRow * columnCount + columnOffset + 1] = FirmwareKeymapEntry(
                keycode: keycode,
                semantic: 0,
                style: .standard
            )
        }

        let pressIndex = Int(KeymapLayer.lower.rawValue) * matrixSize
            + (rowCount - 1) * columnCount
        entries[pressIndex] = FirmwareKeymapEntry(keycode: 0x00AE, semantic: 0, style: .standard)

        let encoderKeycodes: [(UInt16, UInt16)] = [
            (0x00AA, 0x00A9), (0x00AA, 0x00A9), (0x00AC, 0x00AB),
            (0x00AA, 0x00A9), (0x7844, 0x7843)
        ]
        for keycodes in encoderKeycodes {
            entries.append(FirmwareKeymapEntry(keycode: keycodes.0, semantic: 0, style: .standard))
            entries.append(FirmwareKeymapEntry(keycode: keycodes.1, semantic: 0, style: .standard))
        }

        let firmwareKeymap = FirmwareKeymap(
            keyboardKind: keyboardKind,
            layerCount: layerCount,
            matrixRowCount: rowCount,
            matrixColumnCount: columnCount,
            encoderCount: 1,
            fingerprint: 0,
            entries: entries
        )
        guard let definition = KeymapDefinition(firmwareKeymap: firmwareKeymap) else {
            preconditionFailure("Preview keymap must match supported geometry.")
        }
        return definition
    }
#endif
}

/// The layer and effective keymap state rendered by a transient HUD.
public struct LayerHUDPresentation: Equatable, Sendable {
    public let layer: KeymapLayer
    public let activeLayerMask: UInt32

    public init(layer: KeymapLayer, activeLayerMask: UInt32) {
        self.layer = layer
        self.activeLayerMask = activeLayerMask
    }
}
