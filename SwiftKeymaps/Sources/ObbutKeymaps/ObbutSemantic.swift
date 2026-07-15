import QMKKeymapKit

public extension KeySemantic {
    /// The platform-appropriate screenshot action.
    static let screenshot = KeySemantic(
        id: "com.obbut.screenshot",
        legend: "Screenshot",
        symbol: .camera
    )

    /// The Aerospace window-management modifier chord.
    static let aerospace = KeySemantic(
        id: "com.obbut.aerospace",
        legend: "Aerospace",
        symbol: .windowManagement
    )

    /// The primary pointer button.
    static let pointerLeftClick = KeySemantic(
        id: "com.obbut.pointer.left-click",
        legend: "Left Click",
        symbol: .pointerButton
    )

    /// The secondary pointer button.
    static let pointerRightClick = KeySemantic(
        id: "com.obbut.pointer.right-click",
        legend: "Right Click",
        symbol: .pointerButton
    )

    /// The middle pointer button.
    static let pointerMiddleClick = KeySemantic(
        id: "com.obbut.pointer.middle-click",
        legend: "Middle Click",
        symbol: .pointerButton
    )

    /// Browser backward navigation.
    static let browserBack = KeySemantic(
        id: "com.obbut.browser.back",
        legend: "Browser Back",
        symbol: .browserNavigation
    )

    /// Browser forward navigation.
    static let browserForward = KeySemantic(
        id: "com.obbut.browser.forward",
        legend: "Browser Forward",
        symbol: .browserNavigation
    )

    /// Momentary drag scrolling.
    static let pointerScroll = KeySemantic(
        id: "com.obbut.pointer.scroll",
        legend: "Scroll",
        symbol: .scroll
    )

    /// Momentary precision pointer movement.
    static let pointerSniper = KeySemantic(
        id: "com.obbut.pointer.sniper",
        legend: "Sniper",
        symbol: .pointer
    )

    /// Latched primary-button dragging.
    static let pointerDragLock = KeySemantic(
        id: "com.obbut.pointer.drag-lock",
        legend: "Drag Lock",
        symbol: .lockedPointer
    )

    /// A pointer-sensitivity decrease.
    static let pointerSensitivityDown = KeySemantic(
        id: "com.obbut.pointer.sensitivity-down",
        legend: "Pointer −",
        symbol: .pointer
    )

    /// A pointer-sensitivity increase.
    static let pointerSensitivityUp = KeySemantic(
        id: "com.obbut.pointer.sensitivity-up",
        legend: "Pointer +",
        symbol: .pointer
    )

    /// A drag-scroll speed decrease.
    static let pointerScrollSpeedDown = KeySemantic(
        id: "com.obbut.pointer.scroll-speed-down",
        legend: "Scroll −",
        symbol: .scroll
    )

    /// A drag-scroll speed increase.
    static let pointerScrollSpeedUp = KeySemantic(
        id: "com.obbut.pointer.scroll-speed-up",
        legend: "Scroll +",
        symbol: .scroll
    )

    /// Selects Bluetooth host one.
    static let bluetoothHost1 = KeySemantic(
        id: "com.obbut.bluetooth.host-1",
        legend: "Bluetooth 1",
        symbol: .bluetooth
    )

    /// Selects Bluetooth host two.
    static let bluetoothHost2 = KeySemantic(
        id: "com.obbut.bluetooth.host-2",
        legend: "Bluetooth 2",
        symbol: .bluetooth
    )

    /// Selects Bluetooth host three.
    static let bluetoothHost3 = KeySemantic(
        id: "com.obbut.bluetooth.host-3",
        legend: "Bluetooth 3",
        symbol: .bluetooth
    )

    /// Selects the 2.4 GHz radio.
    static let wireless24GHz = KeySemantic(
        id: "com.obbut.wireless.2-4-ghz",
        legend: "2.4 GHz",
        symbol: .wireless
    )

    /// Displays the keyboard battery level.
    static let batteryLevel = KeySemantic(
        id: "com.obbut.battery-level",
        legend: "Battery",
        symbol: .battery
    )
}
