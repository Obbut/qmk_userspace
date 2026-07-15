import QMKKeymapKit

/// Embedded-safe matrix mapping for the Keychron Q15 Max ANSI encoder layout.
public struct Q15MaxLayout: FirmwareLayout, Sendable {
    public let id: StaticString = "keychron.q15-max.ansi-encoder"
    public let keyCount = 66
    public let matrixRowCount: UInt8 = 5
    public let matrixColumnCount: UInt8 = 14
    public let encoderCount: UInt8 = 2

    public init() {}

    public func keyIndex(row: UInt8, column: UInt8) -> Int? {
        switch row {
        case 0: column < 14 ? Int(column) : nil
        case 1: column < 14 ? 14 + Int(column) : nil
        case 2:
            if column < 12 { 28 + Int(column) } else if column == 13 { 40 } else { nil }
        case 3: column < 14 ? 41 + Int(column) : nil
        case 4:
            switch column {
            case 0...4: 55 + Int(column)
            case 6...8: 54 + Int(column)
            case 10: 63
            case 11: 64
            case 13: 65
            default: nil
            }
        default: nil
        }
    }
}
