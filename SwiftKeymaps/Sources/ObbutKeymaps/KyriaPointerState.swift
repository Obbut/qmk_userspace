/// Allocation-free Cirque state owned by the selected firmware runtime.
public struct KyriaPointerState: Sendable {
    var sensitivityIndex: UInt8 = 2
    var scrollIndex: UInt8 = 2
    var scrollHeld = false
    var sniperHeld = false
    var scrollingWasActive = false
    var scrollAxis: UInt8 = 0
    var mouseAccumulatedX: Int32 = 0
    var mouseAccumulatedY: Int32 = 0
    var scrollAccumulated: Int32 = 0
    var scrollPendingX: Int32 = 0
    var scrollPendingY: Int32 = 0
    var scrollAbsoluteX: UInt16 = 0
    var scrollAbsoluteY: UInt16 = 0

    public init() {}
}
