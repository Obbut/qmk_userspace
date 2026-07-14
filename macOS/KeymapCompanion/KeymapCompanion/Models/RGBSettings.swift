import AppKit
import CoreGraphics

/// The persistent base-layer RGB Matrix configuration shared with QMK.
struct RGBSettings: Equatable, Sendable {
    /// QMK's configured maximum brightness for the Elora and Kyria.
    static let maximumBrightness: UInt8 = 128

    /// QMK's maximum animation speed.
    static let maximumSpeed: UInt8 = 255

    /// A representative configuration used before the first keyboard report.
    static let `default` = RGBSettings(
        isEnabled: true,
        effect: .rainbowLeftToRight,
        hue: 0,
        saturation: 255,
        brightness: maximumBrightness,
        speed: 127
    )

    /// Whether RGB Matrix output is enabled.
    var isEnabled: Bool

    /// The selected base-layer animation.
    var effect: RGBEffect

    /// The QMK hue component from zero through 255.
    var hue: UInt8

    /// The QMK saturation component from zero through 255.
    var saturation: UInt8

    /// The QMK brightness component from zero through the configured maximum.
    var brightness: UInt8

    /// The QMK animation speed from zero through 255.
    var speed: UInt8

    /// Brightness normalized for a native slider.
    var normalizedBrightness: Double {
        get {
            Double(brightness) / Double(Self.maximumBrightness)
        }
        set {
            brightness = Self.byte(
                from: newValue,
                maximum: Self.maximumBrightness
            )
        }
    }

    /// Animation speed normalized for a native slider.
    var normalizedSpeed: Double {
        get {
            Double(speed) / Double(Self.maximumSpeed)
        }
        set {
            speed = Self.byte(from: newValue, maximum: Self.maximumSpeed)
        }
    }

    /// A native color-picker representation of the QMK hue, saturation, and brightness.
    var color: CGColor {
        get {
            NSColor(
                hue: CGFloat(hue) / 255,
                saturation: CGFloat(saturation) / 255,
                brightness: CGFloat(brightness) / CGFloat(Self.maximumBrightness),
                alpha: 1
            ).cgColor
        }
        set {
            guard let color = NSColor(cgColor: newValue)?.usingColorSpace(.deviceRGB) else {
                return
            }
            var selectedHue: CGFloat = 0
            var selectedSaturation: CGFloat = 0
            var selectedBrightness: CGFloat = 0
            var selectedAlpha: CGFloat = 0
            color.getHue(
                &selectedHue,
                saturation: &selectedSaturation,
                brightness: &selectedBrightness,
                alpha: &selectedAlpha
            )
            hue = Self.byte(from: selectedHue, maximum: 255)
            saturation = Self.byte(from: selectedSaturation, maximum: 255)
            brightness = Self.byte(
                from: selectedBrightness,
                maximum: Self.maximumBrightness
            )
        }
    }

    /// Converts a normalized native color component into a bounded QMK byte.
    /// - Parameters:
    ///   - component: A normalized component from zero through one.
    ///   - maximum: The maximum representable QMK value.
    /// - Returns: The rounded, clamped byte value.
    private static func byte(from component: CGFloat, maximum: UInt8) -> UInt8 {
        UInt8(clamping: Int((component.clamped(to: 0...1) * CGFloat(maximum)).rounded()))
    }
}

/// Bounds comparable values to a closed range.
private extension Comparable {
    /// Returns this value constrained to the supplied range.
    /// - Parameter range: The inclusive lower and upper bounds.
    /// - Returns: The original value when in range, or the nearest bound.
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
