import QMKKeymapKit

/// The sole semantic vocabulary used by every Obbut keyboard.
public enum ObbutSemantic: UInt16, CaseIterable, KeySemanticID {
    /// The platform-appropriate screenshot action.
    case screenshot = 1
    /// The Aerospace window-management modifier chord.
    case aerospace = 2

    /// The primary pointer button.
    case pointerLeftClick = 10
    /// The secondary pointer button.
    case pointerRightClick = 11
    /// The middle pointer button.
    case pointerMiddleClick = 12
    /// Browser backward navigation.
    case browserBack = 13
    /// Browser forward navigation.
    case browserForward = 14
    /// Momentary drag scrolling.
    case pointerScroll = 15
    /// Momentary precision pointer movement.
    case pointerSniper = 16
    /// Latched primary-button dragging.
    case pointerDragLock = 17
    /// A pointer-sensitivity decrease.
    case pointerSensitivityDown = 18
    /// A pointer-sensitivity increase.
    case pointerSensitivityUp = 19
    /// A drag-scroll speed decrease.
    case pointerScrollSpeedDown = 20
    /// A drag-scroll speed increase.
    case pointerScrollSpeedUp = 21

    /// Selects Bluetooth host one.
    case bluetoothHost1 = 30
    /// Selects Bluetooth host two.
    case bluetoothHost2 = 31
    /// Selects Bluetooth host three.
    case bluetoothHost3 = 32
    /// Selects the 2.4 GHz radio.
    case wireless24GHz = 33
    /// Displays the keyboard battery level.
    case batteryLevel = 34
}
