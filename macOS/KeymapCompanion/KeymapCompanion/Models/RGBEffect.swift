import Foundation

/// A stable companion-protocol identifier for one supported QMK RGB Matrix effect.
enum RGBEffect: UInt8, CaseIterable, Equatable, Hashable, Identifiable, Sendable {
    /// A uniform color across the keyboard.
    case solidColor = 1

    /// Separate colors for alphanumeric and modifier keys.
    case alphasAndModifiers = 2

    /// A color gradient from the keyboard's top edge to its bottom edge.
    case verticalGradient = 3

    /// A color gradient from the keyboard's left edge to its right edge.
    case horizontalGradient = 4

    /// A single color that repeatedly fades in and out.
    case breathing = 5

    /// Saturation bands that move across the keyboard.
    case saturationBands = 6

    /// Color bands that move across the keyboard.
    case colorBands = 7

    /// Saturation bands arranged around a pinwheel.
    case pinwheelSaturation = 8

    /// Color bands arranged around a pinwheel.
    case pinwheel = 9

    /// Saturation bands arranged in a spiral.
    case spiralSaturation = 10

    /// Color bands arranged in a spiral.
    case spiral = 11

    /// A rainbow that cycles across every key together.
    case rainbowCycle = 12

    /// A rainbow that travels horizontally.
    case rainbowLeftToRight = 13

    /// A rainbow that travels vertically.
    case rainbowUpAndDown = 14

    /// A moving rainbow chevron.
    case movingChevron = 15

    /// A rainbow that cycles outward and inward.
    case cycleOutAndIn = 16

    /// Two mirrored rainbows that cycle outward and inward.
    case dualCycleOutAndIn = 17

    /// A rotating rainbow pinwheel.
    case pinwheelCycle = 18

    /// A rotating rainbow spiral.
    case spiralCycle = 19

    /// Two rotating color beacons.
    case dualBeacon = 20

    /// A rotating rainbow beacon.
    case rainbowBeacon = 21

    /// Multiple rotating rainbow pinwheels.
    case rainbowPinwheels = 22

    /// Random drops derived from the selected color.
    case raindrops = 23

    /// Random drops spanning the full color range.
    case jellybeanRaindrops = 24

    /// A breathing animation that also shifts hue.
    case hueBreathing = 25

    /// A hue that swings back and forth.
    case huePendulum = 26

    /// A traveling hue wave.
    case hueWave = 27

    /// Random colored pixels that fall like rain.
    case pixelRain = 28

    /// Colored pixels that flow across the keyboard.
    case pixelFlow = 29

    /// A shifting fractal made from colored pixels.
    case pixelFractal = 30

    /// The stable effect identifier used by SwiftUI lists.
    var id: UInt8 { rawValue }

    /// The user-facing effect name.
    var displayName: LocalizedStringResource {
        switch self {
        case .solidColor:
            "Solid Color"
        case .alphasAndModifiers:
            "Alphas and Modifiers"
        case .verticalGradient:
            "Vertical Gradient"
        case .horizontalGradient:
            "Horizontal Gradient"
        case .breathing:
            "Breathing"
        case .saturationBands:
            "Saturation Bands"
        case .colorBands:
            "Color Bands"
        case .pinwheelSaturation:
            "Pinwheel Saturation"
        case .pinwheel:
            "Pinwheel"
        case .spiralSaturation:
            "Spiral Saturation"
        case .spiral:
            "Spiral"
        case .rainbowCycle:
            "Rainbow Cycle"
        case .rainbowLeftToRight:
            "Rainbow Left to Right"
        case .rainbowUpAndDown:
            "Rainbow Up and Down"
        case .movingChevron:
            "Moving Chevron"
        case .cycleOutAndIn:
            "Cycle Out and In"
        case .dualCycleOutAndIn:
            "Dual Cycle Out and In"
        case .pinwheelCycle:
            "Pinwheel Cycle"
        case .spiralCycle:
            "Spiral Cycle"
        case .dualBeacon:
            "Dual Beacon"
        case .rainbowBeacon:
            "Rainbow Beacon"
        case .rainbowPinwheels:
            "Rainbow Pinwheels"
        case .raindrops:
            "Raindrops"
        case .jellybeanRaindrops:
            "Jellybean Raindrops"
        case .hueBreathing:
            "Hue Breathing"
        case .huePendulum:
            "Hue Pendulum"
        case .hueWave:
            "Hue Wave"
        case .pixelRain:
            "Pixel Rain"
        case .pixelFlow:
            "Pixel Flow"
        case .pixelFractal:
            "Pixel Fractal"
        }
    }
}
