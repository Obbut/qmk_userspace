import QMKKeymapKit

/// Common actions shared by Obbut firmware modules.
extension Key {
    /// The macOS screenshot chord.
    public static var screenshot: Key {
        Key.four
            .withModifiers(.leftCommand, .leftControl, .leftShift)
            .semantic(.screenshot)
    }

    /// The Aerospace modifier chord.
    public static var aerospace: Key {
        Key.chord(.leftControl, .leftCommand, .rightOption)
            .semantic(.aerospace)
    }

    /// Escape on tap and the Aerospace modifier set on hold.
    public static var escapeAerospace: Key {
        Key.modifierTap(
            .leftControl,
            .leftCommand,
            .rightOption,
            key: .escape
        ).semantic(.aerospace)
    }

    /// Selects Bluetooth host one.
    public static var bluetoothHost1: Key {
        Key.qmk(
            .keychronBluetoothHost1,
            legend: "Bluetooth 1",
            semantic: .bluetoothHost1
        ).style(.wireless)
    }

    /// Selects Bluetooth host two.
    public static var bluetoothHost2: Key {
        Key.qmk(
            .keychronBluetoothHost2,
            legend: "Bluetooth 2",
            semantic: .bluetoothHost2
        ).style(.wireless)
    }

    /// Selects Bluetooth host three.
    public static var bluetoothHost3: Key {
        Key.qmk(
            .keychronBluetoothHost3,
            legend: "Bluetooth 3",
            semantic: .bluetoothHost3
        ).style(.wireless)
    }

    /// Selects the 2.4 GHz radio.
    public static var wireless24GHz: Key {
        Key.qmk(
            .keychronWireless24GHz,
            legend: "2.4 GHz",
            semantic: .wireless24GHz
        ).style(.wireless)
    }

    /// Displays the battery level.
    public static var batteryLevel: Key {
        Key.qmk(
            .keychronBatteryLevel,
            legend: "Battery",
            semantic: .batteryLevel
        ).style(.number)
    }

    /// The primary pointer button.
    public static let pointerLeftClick = Key.qmk(
        .pointerButton1,
        legend: "Left Click",
        semantic: .pointerLeftClick
    ).style(.pointer)

    /// The secondary pointer button.
    public static let pointerRightClick = Key.qmk(
        .pointerButton2,
        legend: "Right Click",
        semantic: .pointerRightClick
    ).style(.pointer)

    /// The middle pointer button.
    public static let pointerMiddleClick = Key.qmk(
        .pointerButton3,
        legend: "Middle Click",
        semantic: .pointerMiddleClick
    ).style(.pointer)

    /// Browser backward navigation.
    public static let browserBack = Key.qmk(
        .browserBack,
        legend: "Browser Back",
        semantic: .browserBack
    ).style(.gaming)

    /// Browser forward navigation.
    public static let browserForward = Key.qmk(
        .browserForward,
        legend: "Browser Forward",
        semantic: .browserForward
    ).style(.gaming)

    /// Momentary drag scrolling.
    public static let pointerScroll = pointerAction(
        .pointerScroll,
        legend: "Scroll",
        semantic: .pointerScroll,
        style: .symbol
    )

    /// Momentary precision pointer movement.
    public static let pointerSniper = pointerAction(
        .pointerSniper,
        legend: "Sniper",
        semantic: .pointerSniper,
        style: .symbol
    )

    /// Latched primary-button dragging.
    public static let pointerDragLock = pointerAction(
        .pointerDragLock,
        legend: "Drag Lock",
        semantic: .pointerDragLock,
        style: .bootloader
    )

    /// Decreases pointer sensitivity.
    public static let pointerSensitivityDown = pointerAction(
        .pointerSensitivityDown,
        legend: "Pointer −",
        semantic: .pointerSensitivityDown,
        style: .decrease
    )

    /// Increases pointer sensitivity.
    public static let pointerSensitivityUp = pointerAction(
        .pointerSensitivityUp,
        legend: "Pointer +",
        semantic: .pointerSensitivityUp,
        style: .increase
    )

    /// Decreases drag-scroll speed.
    public static let pointerScrollSpeedDown = pointerAction(
        .pointerScrollSpeedDown,
        legend: "Scroll −",
        semantic: .pointerScrollSpeedDown,
        style: .decrease
    )

    /// Increases drag-scroll speed.
    public static let pointerScrollSpeedUp = pointerAction(
        .pointerScrollSpeedUp,
        legend: "Scroll +",
        semantic: .pointerScrollSpeedUp,
        style: .increase
    )

    /// Creates a custom Kyria pointer action.
    fileprivate static func pointerAction(
        _ keycode: QMKKeycode,
        legend: StaticString,
        semantic: KeySemantic,
        style: SolidKeyStyle
    ) -> Key {
        .qmk(keycode, legend: legend, semantic: semantic)
            .style(style)
    }
}
