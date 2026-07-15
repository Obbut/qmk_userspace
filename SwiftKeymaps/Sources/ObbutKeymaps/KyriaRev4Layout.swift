import QMKKeymapKit

/// Embedded-safe matrix mapping for SplitKB Kyria Rev4 Halcyon boards.
public struct KyriaRev4Layout: FirmwareLayout, Sendable {
    public let id: StaticString = "splitkb.halcyon.kyria.rev4"
    public let keyCount = 60
    public let matrixRowCount: UInt8 = 10
    public let matrixColumnCount: UInt8 = 7
    public let encoderCount: UInt8 = 1

    public init() {}

    public func keyIndex(row: UInt8, column: UInt8) -> Int? {
        switch row {
        case 0: splitRow(column: column, leftBase: 0)
        case 1: splitRow(column: column, leftBase: 12)
        case 2:
            if column == 0 { 31 } else if (1...6).contains(column) { 30 - Int(column) } else { nil }
        case 3:
            switch column {
            case 0: 44
            case 1: 42
            case 2: 41
            case 3: 30
            case 4: 40
            case 5: 43
            default: nil
            }
        case 4: column < 5 ? 50 + Int(column) : nil
        case 5: rightSplitRow(column: column, base: 6)
        case 6: rightSplitRow(column: column, base: 18)
        case 7:
            if column == 0 { 32 } else if (1...6).contains(column) { 33 + Int(column) } else { nil }
        case 8:
            switch column {
            case 0: 45
            case 1: 47
            case 2: 48
            case 3: 33
            case 4: 49
            case 5: 46
            default: nil
            }
        case 9: column < 5 ? 55 + Int(column) : nil
        default: nil
        }
    }

    fileprivate func splitRow(column: UInt8, leftBase: Int) -> Int? {
        (1...6).contains(column) ? leftBase + 6 - Int(column) : nil
    }

    fileprivate func rightSplitRow(column: UInt8, base: Int) -> Int? {
        (1...6).contains(column) ? base + Int(column) - 1 : nil
    }
}
