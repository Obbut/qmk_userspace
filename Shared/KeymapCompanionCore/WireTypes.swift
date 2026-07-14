/// The keyboard identifier shared by firmware and companion apps.
public typealias KeyboardKind = KeymapProtocol.KeyboardKind

/// The encoder direction shared by firmware and companion apps.
public typealias EncoderDirection = KeymapProtocol.EncoderDirection

/// The key presentation category shared by firmware and companion apps.
public typealias KeyStyle = KeymapProtocol.KeyStyle

/// The RGB effect identifier shared by firmware and companion apps.
public typealias RGBEffect = KeymapProtocol.RGBEffect

extension KeymapProtocol.KeyboardKind {
    /// The product name shown by companion apps.
    public var displayName: String {
        switch self {
        case .kyria:
            "Kyria Rev4"
        case .elora:
            "Elora Rev2"
        }
    }
}

extension KeymapProtocol.RGBEffect: Identifiable {
    public var id: UInt8 { rawValue }

    /// The effect name shown by companion apps.
    public var displayName: String {
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
