/// The persistent base-layer RGB Matrix configuration shared with QMK.
public struct RGBSettings: Equatable, Sendable {
    /// The firmware's maximum accepted brightness value.
    public static let maximumBrightness: UInt8 = 128

    /// The firmware's maximum accepted animation speed.
    public static let maximumSpeed: UInt8 = 255

    /// The initial lighting configuration used before firmware state arrives.
    public static let `default` = RGBSettings(
        isEnabled: true,
        effect: .rainbowLeftToRight,
        hue: 0,
        saturation: 255,
        brightness: maximumBrightness,
        speed: 127
    )

    /// Whether RGB Matrix lighting is enabled.
    public var isEnabled: Bool

    /// The active RGB Matrix effect.
    public var effect: RGBEffect

    /// The base hue in QMK's byte-scale color space.
    public var hue: UInt8

    /// The base saturation in QMK's byte-scale color space.
    public var saturation: UInt8

    /// The brightness, limited by ``maximumBrightness``.
    public var brightness: UInt8

    /// The animation speed in QMK's byte-scale range.
    public var speed: UInt8

    /// Creates a complete RGB Matrix configuration.
    ///
    /// - Parameters:
    ///   - isEnabled: Whether RGB Matrix lighting is enabled.
    ///   - effect: The active RGB Matrix effect.
    ///   - hue: The base hue in QMK's byte-scale color space.
    ///   - saturation: The base saturation in QMK's byte-scale color space.
    ///   - brightness: The brightness, clamped to ``maximumBrightness``.
    ///   - speed: The animation speed in QMK's byte-scale range.
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

    /// The brightness represented in the closed range `0...1`.
    public var normalizedBrightness: Double {
        get { Double(brightness) / Double(Self.maximumBrightness) }
        set {
            brightness = Self.byte(
                fromNormalizedComponent: newValue,
                maximumByteValue: Self.maximumBrightness
            )
        }
    }

    /// The animation speed represented in the closed range `0...1`.
    public var normalizedSpeed: Double {
        get { Double(speed) / Double(Self.maximumSpeed) }
        set {
            speed = Self.byte(
                fromNormalizedComponent: newValue,
                maximumByteValue: Self.maximumSpeed
            )
        }
    }

    /// Returns the bounded QMK byte for a normalized component.
    ///
    /// - Parameters:
    ///   - component: A normalized value; values outside `0...1` are clamped.
    ///   - maximumByteValue: The largest byte value the component accepts.
    /// - Returns: The rounded, bounded byte value.
    public static func byte(
        fromNormalizedComponent component: Double,
        maximumByteValue: UInt8
    ) -> UInt8 {
        UInt8(clamping: Int((min(max(component, 0), 1) * Double(maximumByteValue)).rounded()))
    }
}
