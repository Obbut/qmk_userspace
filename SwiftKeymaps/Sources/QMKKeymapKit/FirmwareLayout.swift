/// The allocation-free matrix mapping required by firmware lookup.
public protocol FirmwareLayout: Sendable {
    /// Stable identity carried by protocol metadata.
    var id: StaticString { get }

    /// Number of logical keys in every layer.
    var keyCount: Int { get }

    /// QMK matrix row count.
    var matrixRowCount: UInt8 { get }

    /// QMK matrix column count.
    var matrixColumnCount: UInt8 { get }

    /// Number of physical encoders.
    var encoderCount: UInt8 { get }

    /// Converts a QMK matrix coordinate to the logical keymap index.
    func keyIndex(row: UInt8, column: UInt8) -> Int?

}
