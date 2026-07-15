/// A deterministic millisecond duration suitable for generated QMK defines.
public struct QMKDuration: Equatable, Hashable, Sendable {
    /// The duration in whole milliseconds.
    public let milliseconds: Int

    /// Creates a duration in whole milliseconds.
    ///
    /// - Parameter milliseconds: A nonnegative millisecond count.
    public init(milliseconds: Int) {
        precondition(milliseconds >= 0, "A QMK duration cannot be negative.")
        self.milliseconds = milliseconds
    }

    /// Creates a duration in whole milliseconds.
    ///
    /// - Parameter value: A nonnegative millisecond count.
    /// - Returns: The duration.
    public static func milliseconds(_ value: Int) -> QMKDuration {
        QMKDuration(milliseconds: value)
    }
}
