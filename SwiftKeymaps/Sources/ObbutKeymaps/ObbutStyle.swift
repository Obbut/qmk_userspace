import QMKKeymapKit

public extension KeyStyle where Self == SolidKeyStyle {
    /// A QWERTY gaming key.
    static var gaming: SolidKeyStyle { .rgb(148, 0, 211) }

    /// A navigation key.
    static var navigation: SolidKeyStyle { .magenta }

    /// A numeric key.
    static var number: SolidKeyStyle { .blue }

    /// A symbol key.
    static var symbol: SolidKeyStyle { .yellow }

    /// A function key.
    static var function: SolidKeyStyle { .rgb(0, 220, 220) }

    /// An increasing or enabling action.
    static var increase: SolidKeyStyle { .green }

    /// A decreasing action.
    static var decrease: SolidKeyStyle { .rgb(0, 50, 0) }

    /// A destructive editing action.
    static var destructive: SolidKeyStyle { .orange }

    /// A bootloader action.
    static var bootloader: SolidKeyStyle { .rgb(255, 68, 68) }

    /// A wireless-radio action.
    static var wireless: SolidKeyStyle { .rgb(0, 220, 220) }

    /// A pointer button or movement action.
    static var pointer: SolidKeyStyle { .rgb(0, 180, 220) }

    /// A neutral operating-system indicator.
    static var operatingSystem: SolidKeyStyle { .white }
}
