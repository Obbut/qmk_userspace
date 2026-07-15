/// The LED interval QMK asks an advanced RGB indicator hook to render.
public struct RGBIndicatorRange: Sendable {
    public let lowerBound: UInt8
    public let upperBound: UInt8

    public init(lowerBound: UInt8, upperBound: UInt8) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }
}
