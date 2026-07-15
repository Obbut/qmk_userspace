import QMKKeymapKit

/// Generates a typed QMK callback bridge without requiring an authored C file.
///
/// Each supplied symbol is a host `QMKToken` and must be implemented in the
/// selected board's Embedded Swift source with `@c @implementation`. Omitted
/// callbacks generate no glue.
@freestanding(expression)
public macro qmkBridge(
    id: String,
    keyboardPostInit: QMKToken? = nil,
    housekeeping: QMKToken? = nil,
    processRecord: QMKToken? = nil,
    layerStateSet: QMKToken? = nil,
    pointingDeviceInit: QMKToken? = nil,
    pointingDeviceTask: QMKToken? = nil,
    rgbMatrixIndicatorsAdvanced: QMKToken? = nil,
    rawHIDReceive: QMKToken? = nil
) -> QMKBridgeFeature = #externalMacro(
    module: "QMKKeymapMacrosPlugin",
    type: "QMKBridgeMacro"
)
