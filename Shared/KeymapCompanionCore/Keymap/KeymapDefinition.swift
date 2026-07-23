import ObbutKeyboardCatalog
import QMKFirmwareHost
import QMKFirmwareRuntime
import QMKKeymapKit

/// Renderer input for one catalog-backed keyboard layout.
public struct KeymapDefinition: Equatable, Sendable {
    /// The stable protocol-v5 layout identifier.
    public let layoutID: LayoutID

    /// The keyboard name supplied by its layout descriptor.
    public let displayName: String

    /// The model's renderer geometry.
    public let geometry: KeyboardGeometry

    /// Layers in firmware index order.
    public let supportedLayers: [KeymapLayer]

    /// The physical switches and their firmware-owned mappings.
    public let positionedKeys: [PositionedKey]

    /// Every physical encoder supplied by the layout descriptor.
    public let encoders: [KeymapEncoder]

    /// Whether legend IDs were resolved using identical generated metadata.
    public let legendsMatch: Bool

    /// Whether style IDs were resolved using identical generated metadata.
    public let stylesMatch: Bool

    /// Creates renderer input from a validated firmware keymap.
    ///
    /// Returns `nil` when the layout is unknown or its compiled dimensions do not
    /// match the catalogued layout descriptor.
    ///
    /// - Parameter firmwareKeymap: The complete firmware keymap to transform.
    public init?(firmwareKeymap: FirmwareKeymap) {
        guard let firmware = ObbutKeyboardCatalog.firmware(layoutID: firmwareKeymap.layoutID.rawValue)
        else { return nil }
        self.init(firmwareKeymap: firmwareKeymap, firmware: firmware)
    }

    /// Returns the highest supported layer in a QMK layer mask.
    ///
    /// - Parameter mask: The effective momentary and default layer mask.
    /// - Returns: The highest active supported layer.
    public func highestActiveLayer(in mask: UInt32) -> KeymapLayer {
        KeymapLayer.highestActiveLayer(inLayerMask: mask, supportedLayers: supportedLayers)
    }

    /// Builds preview data from a catalogued firmware definition.
    ///
    /// - Parameter layoutID: The catalog layout to preview.
    /// - Returns: Renderer input for every layer and encoder.
    public static func makePreview(for layoutID: LayoutID) -> KeymapDefinition {
        guard let firmware = ObbutKeyboardCatalog.firmware(layoutID: layoutID.rawValue) else {
            preconditionFailure("Xcode previews require a layout from ObbutKeyboardCatalog.")
        }
        let descriptor = firmware.layout
        let matrixSize = descriptor.matrixRowCount * descriptor.matrixColumnCount
        var entries: [FirmwareKeymapEntry] = []
        entries.reserveCapacity(
            firmware.layers.count
                * (matrixSize + descriptor.encoders.count * EncoderDirection.allCases.count)
        )
        for layer in firmware.layers {
            var matrix = Array(repeating: FirmwareKeymapEntry.unassigned, count: matrixSize)
            for (key, position) in zip(layer.keys, descriptor.matrixMapping) {
                matrix[position.row * descriptor.matrixColumnCount + position.column] =
                    key.previewEntry
            }
            entries.append(contentsOf: matrix)
        }
        for layer in firmware.layers {
            for encoder in descriptor.encoders.sorted(by: { $0.index < $1.index }) {
                let firmwareEncoder = firmware.encoders.first { $0.index == encoder.index }
                let mapping = firmwareEncoder?.mappings.first { $0.layer == layer.id }
                entries.append(mapping?.counterclockwise.previewEntry ?? .unassigned)
                entries.append(mapping?.clockwise.previewEntry ?? .unassigned)
            }
        }
        let previewKeymap = FirmwareKeymap(
            layoutID: layoutID,
            layerCount: firmware.layers.count,
            matrixRowCount: descriptor.matrixRowCount,
            matrixColumnCount: descriptor.matrixColumnCount,
            encoderCount: descriptor.encoders.count,
            fingerprint: 0,
            legendFingerprint: firmware.legendFingerprint,
            styleFingerprint: firmware.styleFingerprint,
            entries: entries
        )
        guard let definition = KeymapDefinition(firmwareKeymap: previewKeymap, firmware: firmware) else {
            preconditionFailure("Firmware must match its catalogued layout descriptor.")
        }
        return definition
    }

    /// Resolves live keymap data against the matching compiled firmware definition.
    ///
    /// - Parameters:
    ///   - firmwareKeymap: The live compiled keymap.
    ///   - firmware: The matching host-side firmware definition.
    private init?(firmwareKeymap: FirmwareKeymap, firmware: AnyFirmware) {
        let descriptor = firmware.layout
        let layers = firmware.layers.map {
            KeymapLayer(
                rawValue: $0.id.rawValue,
                displayName: $0.name,
                isHUDLayer: $0.showsHUD
            )
        }
        let matrixEntryCount =
            firmwareKeymap.layerCount
            * firmwareKeymap.matrixRowCount
            * firmwareKeymap.matrixColumnCount
        let encoderEntryCount =
            firmwareKeymap.layerCount
            * firmwareKeymap.encoderCount
            * EncoderDirection.allCases.count
        guard firmwareKeymap.layerCount == firmware.layers.count,
            firmwareKeymap.matrixRowCount == descriptor.matrixRowCount,
            firmwareKeymap.matrixColumnCount == descriptor.matrixColumnCount,
            firmwareKeymap.encoderCount == descriptor.encoders.count,
            firmwareKeymap.entries.count == matrixEntryCount + encoderEntryCount,
            Set(descriptor.keys.map(\.matrixPosition)).count == descriptor.keys.count,
            layers.enumerated().allSatisfy({ $0.offset == Int($0.element.rawValue) })
        else {
            return nil
        }

        let legendsMatch =
            firmwareKeymap.legendFingerprint == firmware.legendFingerprint
        let stylesMatch =
            firmwareKeymap.styleFingerprint == firmware.styleFingerprint
        let resolver = KeyMetadataResolver(
            firmware: firmware,
            legendsMatch: legendsMatch,
            stylesMatch: stylesMatch
        )

        var positionedKeys: [PositionedKey] = []
        positionedKeys.reserveCapacity(descriptor.keys.count)
        for placement in descriptor.keys {
            let position = placement.matrixPosition
            let entries = layers.compactMap {
                firmwareKeymap.entry(
                    onLayer: Int($0.rawValue),
                    row: position.row,
                    column: position.column
                )
            }
            guard entries.count == layers.count else { return nil }
            positionedKeys.append(
                PositionedKey(
                    key: Self.makeKey(
                        id: "r\(position.row)c\(position.column)",
                        entries: entries,
                        layers: layers,
                        resolver: resolver
                    ),
                    placement: Self.placement(from: placement.geometry)
                )
            )
        }

        var encoders: [KeymapEncoder] = []
        encoders.reserveCapacity(descriptor.encoders.count)
        for encoder in descriptor.encoders.sorted(by: { $0.index < $1.index }) {
            let counterclockwiseEntries = layers.compactMap {
                firmwareKeymap.encoderEntry(
                    onLayer: Int($0.rawValue),
                    encoderIndex: encoder.index,
                    direction: .counterclockwise
                )
            }
            let clockwiseEntries = layers.compactMap {
                firmwareKeymap.encoderEntry(
                    onLayer: Int($0.rawValue),
                    encoderIndex: encoder.index,
                    direction: .clockwise
                )
            }
            let pressEntries: [FirmwareKeymapEntry]
            if let pressPosition = encoder.pressPosition {
                pressEntries = layers.compactMap {
                    firmwareKeymap.entry(
                        onLayer: Int($0.rawValue),
                        row: pressPosition.row,
                        column: pressPosition.column
                    )
                }
            } else {
                pressEntries = Array(repeating: .unassigned, count: layers.count)
            }
            guard counterclockwiseEntries.count == layers.count,
                clockwiseEntries.count == layers.count,
                pressEntries.count == layers.count
            else { return nil }

            let pressID = encoder.pressPosition.map { "r\($0.row)c\($0.column)" }
                ?? "encoder-\(encoder.id)-press"
            encoders.append(
                KeymapEncoder(
                    id: "encoder-\(encoder.id)",
                    placement: Self.placement(from: encoder.geometry),
                    counterclockwiseKey: Self.makeKey(
                        id: "encoder-\(encoder.id)-ccw",
                        entries: counterclockwiseEntries,
                        layers: layers,
                        resolver: resolver
                    ),
                    pressKey: Self.makeKey(
                        id: pressID,
                        entries: pressEntries,
                        layers: layers,
                        resolver: resolver
                    ),
                    clockwiseKey: Self.makeKey(
                        id: "encoder-\(encoder.id)-cw",
                        entries: clockwiseEntries,
                        layers: layers,
                        resolver: resolver
                    )
                )
            )
        }

        layoutID = firmwareKeymap.layoutID
        displayName = descriptor.displayName
        geometry = KeyboardGeometry(
            canvasWidth: descriptor.canvasWidth,
            canvasHeight: descriptor.canvasHeight,
            placements: descriptor.keys.map { Self.placement(from: $0.geometry) },
            matrixPositions: descriptor.keys.map {
                MatrixPosition(row: $0.matrixPosition.row, column: $0.matrixPosition.column)
            },
            encoderPlacements: descriptor.encoders.map { Self.placement(from: $0.geometry) }
        )
        supportedLayers = layers
        self.positionedKeys = positionedKeys
        self.encoders = encoders
        self.legendsMatch = legendsMatch
        self.stylesMatch = stylesMatch
    }

    /// Produces one metadata-resolved key from layer-major firmware entries.
    private static func makeKey(
        id: String,
        entries: [FirmwareKeymapEntry],
        layers: [KeymapLayer],
        resolver: KeyMetadataResolver
    ) -> KeymapKey {
        KeymapKey(
            id: id,
            entries: entries,
            legends: entries.map {
                QMKKeycodeLegend.legend(
                    for: $0,
                    explicitLegend: resolver.legend(for: $0.legendID),
                    legendSymbolName: resolver.legendSymbolName(for: $0.legendID),
                    style: resolver.style(for: $0.styleID),
                    layers: layers
                )
            }
        )
    }

    /// Converts framework geometry to the stable companion rendering model.
    private static func placement(
        from placement: QMKFirmwareHost.PhysicalKeyPlacement
    ) -> PhysicalKeyPlacement {
        PhysicalKeyPlacement(
            centerX: placement.centerX,
            centerY: placement.centerY,
            rotationDegrees: placement.rotationDegrees,
            width: placement.width,
            height: placement.height
        )
    }
}

/// Resolves generated IDs while preserving useful mismatch diagnostics.
fileprivate struct KeyMetadataResolver {
    /// The matching host-side firmware definition.
    let firmware: AnyFirmware

    /// Whether legend values may be interpreted safely.
    let legendsMatch: Bool

    /// Whether style values may be interpreted safely.
    let stylesMatch: Bool

    /// Returns the matching explicit legend.
    func legend(for id: LegendID) -> String? {
        guard id != .none, legendsMatch else { return nil }
        return firmware.legends.first { $0.id == id.rawValue }?.label
    }

    /// Returns the native symbol explicitly selected by the matching legend.
    func legendSymbolName(for id: LegendID) -> String? {
        guard id != .none, legendsMatch else { return nil }
        return firmware.legends.first { $0.id == id.rawValue }?.symbolName
    }

    /// Returns resolved style presentation or a visible unknown-style fallback.
    func style(for id: StyleID) -> ResolvedKeyStyle {
        guard stylesMatch,
            let style = firmware.styles.first(where: { $0.id == id.rawValue })
        else {
            return ResolvedKeyStyle(
                id: id,
                red: ResolvedKeyStyle.standard.red,
                green: ResolvedKeyStyle.standard.green,
                blue: ResolvedKeyStyle.standard.blue,
                isKnown: false
            )
        }
        return ResolvedKeyStyle(
            id: id,
            red: style.color.red,
            green: style.color.green,
            blue: style.color.blue,
            isKnown: true
        )
    }
}

/// Common empty firmware entry used for encoder controls without a press switch.
fileprivate extension FirmwareKeymapEntry {
    static let unassigned = FirmwareKeymapEntry(
        keycode: 0,
        legendID: .none,
        styleID: .standard
    )
}

/// Converts source key actions before QMK compiles their expressions.
fileprivate extension AnyFirmwareKey {
    var previewEntry: FirmwareKeymapEntry {
        FirmwareKeymapEntry(
            keycode: keycode,
            legendID: LegendID(rawValue: legendID ?? 0),
            styleID: StyleID(rawValue: styleID)
        )
    }
}
