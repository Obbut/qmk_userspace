/// The layers shared by the Elora and Kyria firmware.
public enum KeymapLayer: UInt8, CaseIterable, Equatable, Hashable, Identifiable, Sendable {
    /// The default typing layer.
    case base = 0
    /// The alternate QWERTY gaming layer.
    case qwerty = 1
    /// The lower symbol and navigation layer.
    case lower = 2
    /// The raised symbol and numeric layer.
    case raise = 3
    /// The function and system-control layer.
    case function = 4

    /// The firmware layer index.
    public var id: UInt8 { rawValue }

    /// The layer name shown in selection controls.
    public var displayName: String {
        switch self {
        case .base: "Default"
        case .qwerty: "QWERTY"
        case .lower: "Lower"
        case .raise: "Raise"
        case .function: "Function"
        }
    }

    /// The compact layer name shown on key legends.
    public var legendName: String {
        self == .function ? "Fn" : displayName
    }

    /// Whether activating the layer is eligible to present the transient HUD.
    public var isHUDLayer: Bool {
        switch self {
        case .base, .qwerty: false
        case .lower, .raise, .function: true
        }
    }

    /// Returns whether this layer is set in a firmware layer mask.
    ///
    /// - Parameter mask: The firmware layer bit mask.
    ///
    /// - Returns: `true` when this layer's bit is set.
    public func isActive(inLayerMask mask: UInt32) -> Bool {
        mask & (UInt32(1) << UInt32(rawValue)) != 0
    }

    /// Returns the highest known layer set in a firmware layer mask.
    ///
    /// - Parameter mask: The firmware layer bit mask.
    ///
    /// - Returns: The highest active layer, or ``base`` when no known layer is set.
    public static func highestActiveLayer(inLayerMask mask: UInt32) -> KeymapLayer {
        allCases.reversed().first { $0.isActive(inLayerMask: mask) } ?? .base
    }
}
