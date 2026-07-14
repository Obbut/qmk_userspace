import Foundation
import KeymapCompanionCore
import UWP

/// Windows color conversion for the shared RGB Matrix configuration.
extension RGBSettings {
    /// The Windows color represented by the QMK HSV components.
    var rgbColor: Color {
        let hueComponent = Double(hue) / 255
        let saturationComponent = Double(saturation) / 255
        let valueComponent = Double(brightness) / Double(Self.maximumBrightness)
        let sector = Int(floor(hueComponent * 6)) % 6
        let fraction = hueComponent * 6 - floor(hueComponent * 6)
        let lowerValue = valueComponent * (1 - saturationComponent)
        let descendingValue = valueComponent * (1 - fraction * saturationComponent)
        let ascendingValue = valueComponent * (1 - (1 - fraction) * saturationComponent)
        let components: (red: Double, green: Double, blue: Double) =
            switch sector {
            case 0: (valueComponent, ascendingValue, lowerValue)
            case 1: (descendingValue, valueComponent, lowerValue)
            case 2: (lowerValue, valueComponent, ascendingValue)
            case 3: (lowerValue, descendingValue, valueComponent)
            case 4: (ascendingValue, lowerValue, valueComponent)
            default: (valueComponent, lowerValue, descendingValue)
            }
        return Color(
            a: 255,
            r: UInt8(clamping: Int((components.red * 255).rounded())),
            g: UInt8(clamping: Int((components.green * 255).rounded())),
            b: UInt8(clamping: Int((components.blue * 255).rounded()))
        )
    }

    /// Replaces QMK HSV components with a Windows RGB color.
    ///
    /// - Parameter color: The Windows color to convert.
    mutating func setColor(_ color: Color) {
        let red = Double(color.r) / 255
        let green = Double(color.g) / 255
        let blue = Double(color.b) / 255
        let maximum = max(red, green, blue)
        let minimum = min(red, green, blue)
        let delta = maximum - minimum
        var selectedHue = 0.0
        if delta != 0 {
            if maximum == red {
                selectedHue = ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
            } else if maximum == green {
                selectedHue = (blue - red) / delta + 2
            } else {
                selectedHue = (red - green) / delta + 4
            }
            selectedHue /= 6
            if selectedHue < 0 { selectedHue += 1 }
        }
        hue = Self.byte(fromNormalizedComponent: selectedHue, maximumByteValue: 255)
        saturation = Self.byte(
            fromNormalizedComponent: maximum == 0 ? 0 : delta / maximum,
            maximumByteValue: 255
        )
        brightness = Self.byte(
            fromNormalizedComponent: maximum,
            maximumByteValue: Self.maximumBrightness
        )
    }
}
