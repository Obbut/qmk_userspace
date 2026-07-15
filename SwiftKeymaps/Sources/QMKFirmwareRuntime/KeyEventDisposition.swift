/// Whether later features and QMK should continue processing a key event.
public enum KeyEventDisposition: Sendable {
    case continueProcessing
    case handled
}
