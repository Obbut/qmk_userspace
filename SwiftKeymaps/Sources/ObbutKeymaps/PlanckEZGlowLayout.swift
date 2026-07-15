import QMKKeymapKit

/// Embedded-safe matrix mapping for the ZSA Planck EZ Glow two-unit spacebar layout.
public struct PlanckEZGlowLayout: FirmwareLayout, Sendable {
    public let id: StaticString = "zsa.planck-ez.glow"
    public let keyCount = 47
    public let matrixRowCount: UInt8 = 8
    public let matrixColumnCount: UInt8 = 6
    public let encoderCount: UInt8 = 0

    public init() {}

    public func keyIndex(row: UInt8, column: UInt8) -> Int? {
        guard column < 6 else { return nil }
        return switch row {
        case 0: Int(column)
        case 1: 12 + Int(column)
        case 2: 24 + Int(column)
        case 3:
            if column < 3 { 36 + Int(column) } else if column < 5 { 42 + Int(column) } else { nil }
        case 4: 6 + Int(column)
        case 5: 18 + Int(column)
        case 6: 30 + Int(column)
        case 7:
            if column < 3 { 42 + Int(column) } else { 36 + Int(column) }
        default: nil
        }
    }
}
