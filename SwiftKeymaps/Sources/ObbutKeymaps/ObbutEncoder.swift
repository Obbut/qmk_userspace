import QMKKeymapKit

/// Reusable encoder maps for Obbut keyboards.
public enum ObbutEncoder {
    /// Uses the pointer-layer mapping only on Kyria.
    @_alwaysEmitIntoClient
    @inline(__always)
    public static func halcyon(includesPointerLayer: Bool) -> HalcyonEncoderDefinition {
        HalcyonEncoderDefinition(includesPointerLayer: includesPointerLayer)
    }
}

/// The allocation-free Halcyon encoder definition.
public struct HalcyonEncoderDefinition: KeymapDefinition {
    public let includesPointerLayer: Bool

    @_alwaysEmitIntoClient
    @inline(__always)
    public init(includesPointerLayer: Bool) {
        self.includesPointerLayer = includesPointerLayer
    }

    public var layerCount: Int { 0 }
    public var encoderCount: Int { 1 }

    public func layer(at ordinal: Int) -> KeymapLayerMetadata? { nil }
    public func key(at index: Int, onLayer layerOrdinal: Int) -> Key? { nil }

    public func encoder(at ordinal: Int) -> KeymapEncoderMetadata? {
        ordinal == 0 ? KeymapEncoderMetadata(index: 0, id: "right") : nil
    }

    public func encoderMapping(onLayer layerOrdinal: Int, encoderAt encoderOrdinal: Int) -> On? {
        guard encoderOrdinal == 0 else { return nil }
        return switch layerOrdinal {
        case Int(ObbutLayer.base.rawValue):
            On(ObbutLayer.base, counterclockwise: .keyboardVolumeDown, clockwise: .keyboardVolumeUp)
        case Int(ObbutLayer.qwerty.rawValue):
            On(ObbutLayer.qwerty, counterclockwise: .keyboardVolumeDown, clockwise: .keyboardVolumeUp)
        case Int(ObbutLayer.lower.rawValue):
            On(ObbutLayer.lower, counterclockwise: .previousTrack, clockwise: .nextTrack)
        case Int(ObbutLayer.raise.rawValue):
            On(ObbutLayer.raise, counterclockwise: .keyboardVolumeDown, clockwise: .keyboardVolumeUp)
        case Int(ObbutLayer.function.rawValue):
            On(
                ObbutLayer.function,
                counterclockwise: .qmk(.rgbMatrixPrevious, legend: "Previous").style(.decrease),
                clockwise: .qmk(.rgbMatrixNext, legend: "Next").style(.increase)
            )
        case Int(ObbutLayer.pointer.rawValue) where includesPointerLayer:
            On(
                ObbutLayer.pointer,
                counterclockwise: .keyboardVolumeDown,
                clockwise: .keyboardVolumeUp
            )
        default:
            nil
        }
    }
}
