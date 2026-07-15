/// One QMK key event passed through the selected feature tuple.
public struct KeyEvent: Sendable {
    public let keycode: UInt16
    public let isPressed: Bool

    public init(keycode: UInt16, isPressed: Bool) {
        self.keycode = keycode
        self.isPressed = isPressed
    }
}
