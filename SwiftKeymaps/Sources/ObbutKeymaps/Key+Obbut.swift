import QMKKeymapKit

/// Common actions shared by Obbut firmware modules.
extension Key {
    /// The macOS screenshot chord.
    public static var screenshot: Key {
        Key.four
            .withModifiers(.leftCommand, .leftControl, .leftShift)
            .labeled(Legend("Screenshot", icon: .camera))
    }

    /// The Aerospace modifier chord.
    public static var aerospace: Key {
        Key.chord(.leftControl, .leftCommand, .rightOption)
            .labeled(Legend("Aerospace", icon: .windowManagement))
    }

    /// Escape on tap and the Aerospace modifier set on hold.
    public static var escapeAerospace: Key {
        Key.modifierTap(
            .leftControl,
            .leftCommand,
            .rightOption,
            key: .escape
        ).labeled(Legend("Aerospace", icon: .windowManagement))
    }

    /// Selects Bluetooth host one.
    public static var bluetoothHost1: Key {
        Key.qmk(
            .keychronBluetoothHost1,
            legend: Legend("Bluetooth 1", icon: .bluetooth)
        ).style(.wireless)
    }

    /// Selects Bluetooth host two.
    public static var bluetoothHost2: Key {
        Key.qmk(
            .keychronBluetoothHost2,
            legend: Legend("Bluetooth 2", icon: .bluetooth)
        ).style(.wireless)
    }

    /// Selects Bluetooth host three.
    public static var bluetoothHost3: Key {
        Key.qmk(
            .keychronBluetoothHost3,
            legend: Legend("Bluetooth 3", icon: .bluetooth)
        ).style(.wireless)
    }

    /// Selects the 2.4 GHz radio.
    public static var wireless24GHz: Key {
        Key.qmk(
            .keychronWireless24GHz,
            legend: Legend("2.4 GHz", icon: .wireless)
        ).style(.wireless)
    }

    /// Displays the battery level.
    public static var batteryLevel: Key {
        Key.qmk(
            .keychronBatteryLevel,
            legend: Legend("Battery", icon: .battery)
        ).style(.number)
    }

    /// The primary pointer button.
    public static let pointerLeftClick = Key.qmk(
        .pointerButton1,
        legend: Legend("Left Click", icon: .pointerButton)
    ).style(.pointer)

    /// The secondary pointer button.
    public static let pointerRightClick = Key.qmk(
        .pointerButton2,
        legend: Legend("Right Click", icon: .pointerButton)
    ).style(.pointer)

    /// The middle pointer button.
    public static let pointerMiddleClick = Key.qmk(
        .pointerButton3,
        legend: Legend("Middle Click", icon: .pointerButton)
    ).style(.pointer)

    /// Browser backward navigation.
    public static let browserBack = Key.qmk(
        .browserBack,
        legend: Legend("Browser Back", icon: .browserNavigation)
    ).style(.gaming)

    /// Browser forward navigation.
    public static let browserForward = Key.qmk(
        .browserForward,
        legend: Legend("Browser Forward", icon: .browserNavigation)
    ).style(.gaming)

    /// Momentary drag scrolling.
    public static let pointerScroll = pointerAction(
        .pointerScroll,
        legend: Legend("Scroll", icon: .scroll),
        style: .symbol
    )

    /// Momentary precision pointer movement.
    public static let pointerSniper = pointerAction(
        .pointerSniper,
        legend: Legend("Sniper", icon: .pointer),
        style: .symbol
    )

    /// Latched primary-button dragging.
    public static let pointerDragLock = pointerAction(
        .pointerDragLock,
        legend: Legend("Drag Lock", icon: .lockedPointer),
        style: .bootloader
    )

    /// Decreases pointer sensitivity.
    public static let pointerSensitivityDown = pointerAction(
        .pointerSensitivityDown,
        legend: Legend("Pointer −", icon: .pointer),
        style: .decrease
    )

    /// Increases pointer sensitivity.
    public static let pointerSensitivityUp = pointerAction(
        .pointerSensitivityUp,
        legend: Legend("Pointer +", icon: .pointer),
        style: .increase
    )

    /// Decreases drag-scroll speed.
    public static let pointerScrollSpeedDown = pointerAction(
        .pointerScrollSpeedDown,
        legend: Legend("Scroll −", icon: .scroll),
        style: .decrease
    )

    /// Increases drag-scroll speed.
    public static let pointerScrollSpeedUp = pointerAction(
        .pointerScrollSpeedUp,
        legend: Legend("Scroll +", icon: .scroll),
        style: .increase
    )

    /// Creates a custom Kyria pointer action.
    fileprivate static func pointerAction(
        _ keycode: QMKKeycode,
        legend: Legend,
        style: SolidKeyStyle
    ) -> Key {
        .qmk(keycode, legend: legend)
            .style(style)
    }
}
