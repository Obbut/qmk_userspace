import AppKit
import CoreGraphics
import KeymapCompanionCore

typealias RGBSettings = KeymapCompanionCore.RGBSettings

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
            hue = Self.byte(from: Double(selectedHue), maximum: 255)
            saturation = Self.byte(from: Double(selectedSaturation), maximum: 255)
            brightness = Self.byte(
                from: Double(selectedBrightness),
                maximum: Self.maximumBrightness
            )
        }
    }
}
