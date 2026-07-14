/// The layers shared by the Elora and Kyria firmware.
public enum KeymapLayer: UInt8, CaseIterable, Equatable, Hashable, Identifiable, Sendable {
    case base = 0
    case qwerty = 1
    case lower = 2
    case raise = 3
    case function = 4

    public var id: UInt8 { rawValue }

    public var displayName: String {
        switch self {
        case .base: "Default"
        case .qwerty: "QWERTY"
        case .lower: "Lower"
        case .raise: "Raise"
        case .function: "Function"
        }
    }

    public var legendName: String {
        self == .function ? "Fn" : displayName
    }

    public var isHUDLayer: Bool {
        switch self {
        case .base, .qwerty: false
        case .lower, .raise, .function: true
        }
    }

    public func isActive(in mask: UInt32) -> Bool {
        mask & (UInt32(1) << UInt32(rawValue)) != 0
    }

    public static func highestActiveLayer(in mask: UInt32) -> KeymapLayer {
        allCases.reversed().first { $0.isActive(in: mask) } ?? .base
    }
}
