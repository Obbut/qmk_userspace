/// The persistent base-layer RGB Matrix configuration shared with QMK.
public struct RGBSettings: Equatable, Sendable {
    public static let maximumBrightness: UInt8 = 128
    public static let maximumSpeed: UInt8 = 255

    public static let `default` = RGBSettings(
        isEnabled: true,
        effect: .rainbowLeftToRight,
        hue: 0,
        saturation: 255,
        brightness: maximumBrightness,
        speed: 127
    )

    public var isEnabled: Bool
    public var effect: RGBEffect
    public var hue: UInt8
    public var saturation: UInt8
    public var brightness: UInt8
    public var speed: UInt8

    public init(
        isEnabled: Bool,
        effect: RGBEffect,
        hue: UInt8,
        saturation: UInt8,
        brightness: UInt8,
        speed: UInt8
    ) {
        self.isEnabled = isEnabled
        self.effect = effect
        self.hue = hue
        self.saturation = saturation
        self.brightness = min(brightness, Self.maximumBrightness)
        self.speed = speed
    }

    public var normalizedBrightness: Double {
        get { Double(brightness) / Double(Self.maximumBrightness) }
        set { brightness = Self.byte(from: newValue, maximum: Self.maximumBrightness) }
    }

    public var normalizedSpeed: Double {
        get { Double(speed) / Double(Self.maximumSpeed) }
        set { speed = Self.byte(from: newValue, maximum: Self.maximumSpeed) }
    }

    /// Converts a normalized value into a bounded QMK byte.
    public static func byte(from component: Double, maximum: UInt8) -> UInt8 {
        UInt8(clamping: Int((min(max(component, 0), 1) * Double(maximum)).rounded()))
    }
}
