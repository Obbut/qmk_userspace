/// Stable semantic identifiers carried by keymap entries.
extension KeymapProtocol {
    /// A semantic override for a compiled QMK keycode.
    public enum KeySemantic: UInt8, Equatable, Sendable {
        /// No semantic override.
        case none = 0

        /// The macOS or Windows screenshot action.
        case screenshot = 1

        /// The Aerospace window-manager modifier chord.
        case aerospace = 2

        /// The primary pointer button.
        case pointerLeftClick = 3

        /// The secondary pointer button.
        case pointerRightClick = 4

        /// The middle pointer button.
        case pointerMiddleClick = 5

        /// Browser backward navigation.
        case browserBack = 6

        /// Browser forward navigation.
        case browserForward = 7

        /// Momentary pointer drag scrolling.
        case pointerScroll = 8

        /// Momentary precision pointer movement.
        case pointerSniper = 9

        /// Latched primary-button dragging.
        case pointerDragLock = 10

        /// A pointer-sensitivity decrease.
        case pointerSensitivityDown = 11

        /// A pointer-sensitivity increase.
        case pointerSensitivityUp = 12

        /// A drag-scroll speed decrease.
        case pointerScrollSpeedDown = 13

        /// A drag-scroll speed increase.
        case pointerScrollSpeedUp = 14
    }
}
