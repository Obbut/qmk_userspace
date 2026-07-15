import QMKKeymapKit

/// A last-resort, typed bridge from generated QMK callbacks into custom Swift.
public struct QMKBridgeFeature: FirmwareFeature, Sendable {
    /// Build metadata consumed by the host keymap compiler.
    public let firmwareFeatureDescriptor: FirmwareFeatureDescriptor

    /// Creates a custom Embedded Swift bridge feature.
    ///
    /// - Parameters:
    ///   - id: A stable feature identifier.
    ///   - hooks: Typed callback-to-symbol mappings.
    public init(id: String, hooks: [EmbeddedSwiftHook]) {
        firmwareFeatureDescriptor = FirmwareFeatureDescriptor(
            id: id,
            embeddedSwiftHooks: hooks
        )
    }

    /// Creates a bridge by selecting callbacks with labeled token arguments.
    ///
    /// - Parameters:
    ///   - id: A stable feature identifier.
    ///   - keyboardPostInit: A symbol invoked after QMK initialization.
    ///   - housekeeping: A symbol invoked from periodic housekeeping.
    ///   - processRecord: A symbol that filters or handles key events.
    ///   - layerStateSet: A symbol that transforms layer state.
    ///   - pointingDeviceInit: A symbol that initializes the pointing device.
    ///   - pointingDeviceTask: A symbol that transforms pointing reports.
    ///   - rgbMatrixIndicatorsAdvanced: A symbol that adds RGB Matrix indicators.
    ///   - rawHIDReceive: A symbol that receives Raw HID packets.
    public init(
        id: String,
        keyboardPostInit: QMKToken? = nil,
        housekeeping: QMKToken? = nil,
        processRecord: QMKToken? = nil,
        layerStateSet: QMKToken? = nil,
        pointingDeviceInit: QMKToken? = nil,
        pointingDeviceTask: QMKToken? = nil,
        rgbMatrixIndicatorsAdvanced: QMKToken? = nil,
        rawHIDReceive: QMKToken? = nil
    ) {
        let selections: [(EmbeddedSwiftCallback, QMKToken?)] = [
            (.keyboardPostInit, keyboardPostInit),
            (.housekeeping, housekeeping),
            (.processRecord, processRecord),
            (.layerStateSet, layerStateSet),
            (.pointingDeviceInit, pointingDeviceInit),
            (.pointingDeviceTask, pointingDeviceTask),
            (.rgbMatrixIndicatorsAdvanced, rgbMatrixIndicatorsAdvanced),
            (.rawHIDReceive, rawHIDReceive),
        ]
        self.init(
            id: id,
            hooks: selections.compactMap { callback, token in
                token.map {
                    EmbeddedSwiftHook(callback: callback, symbol: $0.spelling)
                }
            }
        )
    }
}
