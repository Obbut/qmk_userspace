extension KeymapProtocol {
    /// A visual category assigned to a key by the firmware.
    public enum KeyStyle: UInt8, Equatable, Sendable {
        /// A key without a layer-specific RGB category.
        case standard = 0

        /// A QWERTY gaming key.
        case purple = 1

        /// A navigation key.
        case magenta = 2

        /// A numeric key.
        case blue = 3

        /// A symbol key.
        case yellow = 4

        /// A function key.
        case cyan = 5

        /// An RGB increase or mode key.
        case green = 6

        /// An RGB decrease key.
        case darkGreen = 7

        /// A bootloader key.
        case red = 8

        /// A destructive editing key.
        case orange = 9
    }
}
