import QMKKeymapKit

/// Common domain-typed actions shared by Obbut firmware modules.
public enum ObbutKey {
    /// The macOS screenshot chord with a platform semantic override.
    public static var screenshot: Key<ObbutKeymapDomain> {
        Key.four
            .withModifiers(.leftCommand, .leftControl, .leftShift)
            .semantic(.screenshot)
    }

    /// The Aerospace modifier chord.
    public static var aerospace: Key<ObbutKeymapDomain> {
        Key.chord(.leftControl, .leftCommand, .rightOption)
            .semantic(.aerospace)
    }

    /// Escape on tap and the Aerospace modifier set on hold.
    public static var escapeAerospace: Key<ObbutKeymapDomain> {
        Key.escapeAerospace.semantic(.aerospace)
    }

    /// Selects Bluetooth host one.
    public static var bluetoothHost1: Key<ObbutKeymapDomain> {
        #qmkKeycode(
            BT_HST1,
            legend: "Bluetooth 1",
            semantic: .bluetoothHost1,
            style: .wireless
        )
    }

    /// Selects Bluetooth host two.
    public static var bluetoothHost2: Key<ObbutKeymapDomain> {
        #qmkKeycode(
            BT_HST2,
            legend: "Bluetooth 2",
            semantic: .bluetoothHost2,
            style: .wireless
        )
    }

    /// Selects Bluetooth host three.
    public static var bluetoothHost3: Key<ObbutKeymapDomain> {
        #qmkKeycode(
            BT_HST3,
            legend: "Bluetooth 3",
            semantic: .bluetoothHost3,
            style: .wireless
        )
    }

    /// Selects the 2.4 GHz radio.
    public static var wireless24GHz: Key<ObbutKeymapDomain> {
        #qmkKeycode(
            P2P4G,
            legend: "2.4 GHz",
            semantic: .wireless24GHz,
            style: .wireless
        )
    }

    /// Displays the battery level.
    public static var batteryLevel: Key<ObbutKeymapDomain> {
        #qmkKeycode(
            BAT_LVL,
            legend: "Battery",
            semantic: .batteryLevel,
            style: .number
        )
    }

    /// The primary pointer button.
    public static let pointerLeftClick = Key<ObbutKeymapDomain>.qmk(
        "MS_BTN1",
        legend: "Left Click",
        semantic: .pointerLeftClick,
        style: .pointer
    )

    /// The secondary pointer button.
    public static let pointerRightClick = Key<ObbutKeymapDomain>.qmk(
        "MS_BTN2",
        legend: "Right Click",
        semantic: .pointerRightClick,
        style: .pointer
    )

    /// The middle pointer button.
    public static let pointerMiddleClick = Key<ObbutKeymapDomain>.qmk(
        "MS_BTN3",
        legend: "Middle Click",
        semantic: .pointerMiddleClick,
        style: .pointer
    )

    /// Browser backward navigation.
    public static let browserBack = Key<ObbutKeymapDomain>.qmk(
        "KC_WBAK",
        legend: "Browser Back",
        semantic: .browserBack,
        style: .gaming
    )

    /// Browser forward navigation.
    public static let browserForward = Key<ObbutKeymapDomain>.qmk(
        "KC_WFWD",
        legend: "Browser Forward",
        semantic: .browserForward,
        style: .gaming
    )

    /// Momentary drag scrolling.
    public static let pointerScroll = pointerAction(
        "PTR_SCROLL",
        legend: "Scroll",
        semantic: .pointerScroll,
        style: .symbol
    )

    /// Momentary precision pointer movement.
    public static let pointerSniper = pointerAction(
        "PTR_SNIPER",
        legend: "Sniper",
        semantic: .pointerSniper,
        style: .symbol
    )

    /// Latched primary-button dragging.
    public static let pointerDragLock = pointerAction(
        "PTR_DRAG_LOCK",
        legend: "Drag Lock",
        semantic: .pointerDragLock,
        style: .bootloader
    )

    /// Decreases pointer sensitivity.
    public static let pointerSensitivityDown = pointerAction(
        "PTR_SENS_DOWN",
        legend: "Pointer −",
        semantic: .pointerSensitivityDown,
        style: .decrease
    )

    /// Increases pointer sensitivity.
    public static let pointerSensitivityUp = pointerAction(
        "PTR_SENS_UP",
        legend: "Pointer +",
        semantic: .pointerSensitivityUp,
        style: .increase
    )

    /// Decreases drag-scroll speed.
    public static let pointerScrollSpeedDown = pointerAction(
        "PTR_SCROLL_DOWN",
        legend: "Scroll −",
        semantic: .pointerScrollSpeedDown,
        style: .decrease
    )

    /// Increases drag-scroll speed.
    public static let pointerScrollSpeedUp = pointerAction(
        "PTR_SCROLL_UP",
        legend: "Scroll +",
        semantic: .pointerScrollSpeedUp,
        style: .increase
    )

    /// Creates a custom Kyria pointer action.
    fileprivate static func pointerAction(
        _ expression: String,
        legend: String,
        semantic: ObbutSemantic,
        style: ObbutStyle
    ) -> Key<ObbutKeymapDomain> {
        .qmk(expression, legend: legend, semantic: semantic, style: style)
    }
}
