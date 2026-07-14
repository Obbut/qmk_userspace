import KeymapCompanionCore

import SwiftUI

/// A stable RGB Matrix effect identifier.
typealias RGBEffect = KeymapCompanionCore.RGBEffect

/// macOS-localized presentation for shared RGB Matrix effects.
extension KeymapCompanionCore.RGBEffect {
    /// The localized effect name shown by the macOS app.
    var localizedDisplayName: LocalizedStringResource {
        switch self {
        case .solidColor: "Solid Color"
        case .alphasAndModifiers: "Alphas and Modifiers"
        case .verticalGradient: "Vertical Gradient"
        case .horizontalGradient: "Horizontal Gradient"
        case .breathing: "Breathing"
        case .saturationBands: "Saturation Bands"
        case .colorBands: "Color Bands"
        case .pinwheelSaturation: "Pinwheel Saturation"
        case .pinwheel: "Pinwheel"
        case .spiralSaturation: "Spiral Saturation"
        case .spiral: "Spiral"
        case .rainbowCycle: "Rainbow Cycle"
        case .rainbowLeftToRight: "Rainbow Left to Right"
        case .rainbowUpAndDown: "Rainbow Up and Down"
        case .movingChevron: "Moving Chevron"
        case .cycleOutAndIn: "Cycle Out and In"
        case .dualCycleOutAndIn: "Dual Cycle Out and In"
        case .pinwheelCycle: "Pinwheel Cycle"
        case .spiralCycle: "Spiral Cycle"
        case .dualBeacon: "Dual Beacon"
        case .rainbowBeacon: "Rainbow Beacon"
        case .rainbowPinwheels: "Rainbow Pinwheels"
        case .raindrops: "Raindrops"
        case .jellybeanRaindrops: "Jellybean Raindrops"
        case .hueBreathing: "Hue Breathing"
        case .huePendulum: "Hue Pendulum"
        case .hueWave: "Hue Wave"
        case .pixelRain: "Pixel Rain"
        case .pixelFlow: "Pixel Flow"
        case .pixelFractal: "Pixel Fractal"
        }
    }
}
