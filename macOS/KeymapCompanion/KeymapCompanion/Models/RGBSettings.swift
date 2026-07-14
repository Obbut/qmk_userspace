import AppKit
import CoreGraphics
import KeymapCompanionCore

/// A persistent base-layer RGB Matrix configuration.
typealias RGBSettings = KeymapCompanionCore.RGBSettings

/// AppKit color conversion for the shared RGB Matrix configuration.
extension KeymapCompanionCore.RGBSettings {
    /// A native color-picker representation of QMK HSV components.
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
            hue = Self.byte(fromNormalizedComponent: Double(selectedHue), maximumByteValue: 255)
            saturation = Self.byte(
                fromNormalizedComponent: Double(selectedSaturation),
                maximumByteValue: 255
            )
            brightness = Self.byte(
                fromNormalizedComponent: Double(selectedBrightness),
                maximumByteValue: Self.maximumBrightness
            )
        }
    }
}
