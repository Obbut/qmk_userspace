import KeymapCompanionCore

/// An adjustable byte-scale RGB Matrix component shown in the lighting flyout.
enum RGBLevelComponent: Equatable {
    /// The base-layer brightness component.
    case brightness

    /// The animation-speed component.
    case speed

    /// The user-facing component title.
    var title: String {
        switch self {
        case .brightness: "Brightness"
        case .speed: "Animation speed"
        }
    }

    /// The largest firmware byte accepted by this component.
    var maximumValue: UInt8 {
        switch self {
        case .brightness: RGBSettings.maximumBrightness
        case .speed: RGBSettings.maximumSpeed
        }
    }

    /// The amount applied by one increment or decrement action.
    var step: UInt8 {
        switch self {
        case .brightness: 8
        case .speed: 16
        }
    }

    /// Returns this component's value from an RGB configuration.
    ///
    /// - Parameter settings: The RGB configuration to inspect.
    /// - Returns: The component's current byte value.
    func value(in settings: RGBSettings) -> UInt8 {
        switch self {
        case .brightness: settings.brightness
        case .speed: settings.speed
        }
    }

    /// Decreases this component by one bounded step.
    ///
    /// - Parameter settings: The RGB configuration to modify.
    func decrease(in settings: inout RGBSettings) {
        switch self {
        case .brightness:
            settings.brightness = UInt8(clamping: Int(settings.brightness) - Int(step))
        case .speed:
            settings.speed = UInt8(clamping: Int(settings.speed) - Int(step))
        }
    }

    /// Increases this component by one bounded step.
    ///
    /// - Parameter settings: The RGB configuration to modify.
    func increase(in settings: inout RGBSettings) {
        switch self {
        case .brightness:
            settings.brightness = UInt8(clamping: Int(settings.brightness) + Int(step))
        case .speed:
            settings.speed = UInt8(clamping: Int(settings.speed) + Int(step))
        }
    }
}
