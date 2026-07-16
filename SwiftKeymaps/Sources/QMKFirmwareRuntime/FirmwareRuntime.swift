import QMKKeymapKit

/// The specialized, allocation-free runtime for one selected firmware type.
public struct FirmwareRuntime<Firmware: QMKFirmware>: Sendable {
    public typealias FeatureState = Firmware.FeatureBody.State

    public var featureState: FeatureState
    public var context: FirmwareContext

    public init(_ firmware: Firmware.Type = Firmware.self) {
        _ = firmware
        featureState = Firmware.FeatureBody.initialState
        context = FirmwareContext()
    }

    public var layerCount: UInt8 {
        UInt8(truncatingIfNeeded: Firmware.keymap.layerCount)
    }

    public var encoderCount: UInt8 {
        UInt8(truncatingIfNeeded: Firmware.keymap.encoderCount)
    }

    public var layoutID: UInt32 {
        StaticStringContent.fingerprint(Firmware.layout.id)
    }

    public var legendFingerprint: UInt32 {
        context.legendFingerprint
    }

    public var styleFingerprint: UInt32 {
        context.styleFingerprint
    }

    public mutating func postInitialize() {
        updateMetadataFingerprints()
        Firmware.FeatureBody.postInitialize(state: &featureState, context: &context)
    }

    public mutating func housekeeping() {
        Firmware.FeatureBody.housekeeping(state: &featureState, context: &context)
    }

    public mutating func processRecord(keycode: UInt16, isPressed: Bool) -> Bool {
        Firmware.FeatureBody.processRecord(
            KeyEvent(keycode: keycode, isPressed: isPressed),
            state: &featureState,
            context: &context
        ) == .continueProcessing
    }

    public mutating func layerStateSet(_ layerState: UInt32) -> UInt32 {
        var updated = layerState
        context.layerState = layerState
        Firmware.FeatureBody.layerStateSet(
            &updated,
            state: &featureState,
            context: &context
        )
        context.layerState = updated
        return updated
    }

    public mutating func pointingDeviceInitialize() {
        Firmware.FeatureBody.pointingDeviceInitialize(
            state: &featureState,
            context: &context
        )
    }

    public mutating func pointingDeviceTask(_ report: inout PointerReport) {
        Firmware.FeatureBody.pointingDeviceTask(
            &report,
            state: &featureState,
            context: &context
        )
    }

    public mutating func rgbMatrixIndicators(lowerBound: UInt8, upperBound: UInt8) -> Bool {
        Firmware.FeatureBody.rgbMatrixIndicators(
            RGBIndicatorRange(lowerBound: lowerBound, upperBound: upperBound),
            state: &featureState,
            context: &context
        )
    }

    public mutating func rawHIDReceive(
        _ data: UnsafeMutablePointer<UInt8>,
        length: UInt8
    ) -> Bool {
        Firmware.FeatureBody.rawHIDReceive(
            data,
            length: length,
            state: &featureState,
            context: &context
        )
    }

    public mutating func receiveSplitState(rgbPreviewMode: Bool, pointerDragLockActive: Bool) {
        context.rgbPreviewMode = rgbPreviewMode
        context.pointerDragLockActive = pointerDragLockActive
    }

    public mutating func rgbSettingsApplied() {
        context.rgbPreviewMode = context.highestLayer == 4
    }

    public func keycode(layer: UInt8, row: UInt8, column: UInt8) -> UInt16 {
        key(layer: layer, row: row, column: column)?.keycode.rawValue ?? 0
    }

    public func legendID(layer: UInt8, row: UInt8, column: UInt8) -> UInt16 {
        key(layer: layer, row: row, column: column)?.legendID ?? 0
    }

    public func styleID(layer: UInt8, row: UInt8, column: UInt8) -> UInt16 {
        key(layer: layer, row: row, column: column)?.appearance.contentID ?? 0
    }

    public func packedStyleColor(layer: UInt8, row: UInt8, column: UInt8) -> UInt32 {
        guard let appearance = key(layer: layer, row: row, column: column)?.appearance,
            appearance.contentID != 0
        else {
            return 0
        }
        let color = appearance.color
        return UInt32(color.red) << 16 | UInt32(color.green) << 8 | UInt32(color.blue)
    }

    public func encoderKeycode(layer: UInt8, encoder: UInt8, direction: UInt8) -> UInt16 {
        encoderKey(layer: layer, encoder: encoder, direction: direction)?.keycode.rawValue ?? 0
    }

    public func encoderLegendID(layer: UInt8, encoder: UInt8, direction: UInt8) -> UInt16 {
        encoderKey(layer: layer, encoder: encoder, direction: direction)?.legendID ?? 0
    }

    public func encoderStyleID(layer: UInt8, encoder: UInt8, direction: UInt8) -> UInt16 {
        encoderKey(layer: layer, encoder: encoder, direction: direction)?.appearance.contentID ?? 0
    }

    fileprivate func key(layer: UInt8, row: UInt8, column: UInt8) -> Key? {
        guard Int(layer) < Firmware.keymap.layerCount,
            let index = Firmware.layout.keyIndex(row: row, column: column)
        else {
            return nil
        }
        return Firmware.keymap.key(at: index, onLayer: Int(layer))
    }

    fileprivate func encoderKey(layer: UInt8, encoder: UInt8, direction: UInt8) -> Key? {
        guard direction < 2,
            let mapping = Firmware.keymap.encoderMapping(
                onLayer: Int(layer),
                encoderAt: Int(encoder)
            )
        else {
            return nil
        }
        return direction == 0 ? mapping.counterclockwise : mapping.clockwise
    }

    /// Calculates the legend and style fingerprints reported by this firmware.
    ///
    /// - Returns: Fingerprints derived in the same order as embedded lookup traversal.
    public static func metadataFingerprints() -> (legend: UInt32, style: UInt32) {
        FirmwareRuntime().calculatedMetadataFingerprints()
    }

    fileprivate mutating func updateMetadataFingerprints() {
        let fingerprints = calculatedMetadataFingerprints()
        context.legendFingerprint = fingerprints.legend
        context.styleFingerprint = fingerprints.style
    }

    fileprivate func calculatedMetadataFingerprints() -> (legend: UInt32, style: UInt32) {
        var legendHash: UInt32 = 2_166_136_261
        var styleHash: UInt32 = 2_166_136_261
        for layer in 0..<layerCount {
            for keyIndex in 0..<Firmware.layout.keyCount {
                guard let key = Firmware.keymap.key(at: keyIndex, onLayer: Int(layer)) else {
                    continue
                }
                legendHash = Self.add(key.legendID, to: legendHash)
                styleHash = Self.add(key.appearance.contentID, to: styleHash)
            }
            for encoder in 0..<encoderCount {
                for direction in UInt8(0)..<2 {
                    let key = encoderKey(layer: layer, encoder: encoder, direction: direction)
                    legendHash = Self.add(key?.legendID ?? 0, to: legendHash)
                    styleHash = Self.add(key?.appearance.contentID ?? 0, to: styleHash)
                }
            }
        }
        return (legendHash, styleHash)
    }

    fileprivate static func add(_ value: UInt16, to hash: UInt32) -> UInt32 {
        let high = UInt8(truncatingIfNeeded: value >> 8)
        let low = UInt8(truncatingIfNeeded: value)
        return ((hash ^ UInt32(high)) &* 16_777_619 ^ UInt32(low)) &* 16_777_619
    }
}
