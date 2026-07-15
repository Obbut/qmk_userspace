import QMKKeymapKit

/// Embedded-safe matrix mapping for SplitKB Elora Rev2 Halcyon boards.
public struct EloraRev2Layout: FirmwareLayout, Sendable {
    public let id: StaticString = "splitkb.halcyon.elora.rev2"
    public let keyCount = 72
    public let matrixRowCount: UInt8 = 12
    public let matrixColumnCount: UInt8 = 7
    public let encoderCount: UInt8 = 1

    public init() {}

    public func keyIndex(row: UInt8, column: UInt8) -> Int? {
        switch row {
        case 0: leftSplitRow(column: column, base: 0)
        case 1: leftSplitRow(column: column, base: 12)
        case 2: leftSplitRow(column: column, base: 24)
        case 3:
            if column == 0 { 43 } else if (1...6).contains(column) { 42 - Int(column) } else { nil }
        case 4:
            switch column {
            case 0: 56
            case 1: 54
            case 2: 53
            case 3: 42
            case 4: 52
            case 5: 55
            default: nil
            }
        case 5: column < 5 ? 62 + Int(column) : nil
        case 6: rightSplitRow(column: column, base: 6)
        case 7: rightSplitRow(column: column, base: 18)
        case 8: rightSplitRow(column: column, base: 30)
        case 9:
            if column == 0 { 44 } else if (1...6).contains(column) { 45 + Int(column) } else { nil }
        case 10:
            switch column {
            case 0: 57
            case 1: 59
            case 2: 60
            case 3: 45
            case 4: 61
            case 5: 58
            default: nil
            }
        case 11: column < 5 ? 67 + Int(column) : nil
        default: nil
        }
    }

    fileprivate func leftSplitRow(column: UInt8, base: Int) -> Int? {
        (1...6).contains(column) ? base + 6 - Int(column) : nil
    }

    fileprivate func rightSplitRow(column: UInt8, base: Int) -> Int? {
        (1...6).contains(column) ? base + Int(column) - 1 : nil
    }
}
