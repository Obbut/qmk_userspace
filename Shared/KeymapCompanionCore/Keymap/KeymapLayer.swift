/// One firmware-defined layer exposed to renderers and HUDs.
public struct KeymapLayer: Equatable, Hashable, Identifiable, Sendable {
    /// The QMK layer index.
    public let rawValue: UInt8

    /// The full user-facing layer name.
    public let displayName: String

    /// Whether activation should present the transient layer HUD.
    public let isHUDLayer: Bool

    /// Creates a firmware-defined layer.
    ///
    /// - Parameters:
    ///   - rawValue: The QMK layer index.
    ///   - displayName: The user-facing layer name.
    ///   - isHUDLayer: Whether activation should present the HUD.
    public init(rawValue: UInt8, displayName: String, isHUDLayer: Bool) {
        self.rawValue = rawValue
        self.displayName = displayName
        self.isHUDLayer = isHUDLayer
    }

    /// The QMK layer index used as stable identity.
    public var id: UInt8 { rawValue }

    /// The compact layer name shown on key legends.
    public var legendName: String {
        switch displayName {
        case "Function": "Fn"
        case "Pointer": "P"
        default: displayName
        }
    }

    /// Returns whether this layer is set in a firmware layer mask.
    ///
    /// - Parameter mask: The firmware layer bit mask.
    /// - Returns: `true` when this layer's bit is set.
    public func isActive(inLayerMask mask: UInt32) -> Bool {
        mask & (UInt32(1) << UInt32(rawValue)) != 0
    }

    /// Returns the highest supported layer set in a firmware layer mask.
    ///
    /// - Parameters:
    ///   - mask: The firmware layer bit mask.
    ///   - supportedLayers: Layers supplied by the active firmware definition.
    /// - Returns: The highest active layer, or the first supported layer.
    public static func highestActiveLayer(
        inLayerMask mask: UInt32,
        supportedLayers: [KeymapLayer]
    ) -> KeymapLayer {
        supportedLayers.reversed().first { $0.isActive(inLayerMask: mask) }
            ?? supportedLayers.first
            ?? base
    }

    /// A safe placeholder used before firmware metadata is available.
    public static let base = KeymapLayer(rawValue: 0, displayName: "Default", isHUDLayer: false)
}
