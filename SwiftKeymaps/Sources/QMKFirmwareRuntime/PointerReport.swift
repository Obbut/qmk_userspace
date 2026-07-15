/// Primitive, ABI-neutral pointing-device report fields.
public struct PointerReport: Sendable {
    public var x: Int8
    public var y: Int8
    public var horizontal: Int8
    public var vertical: Int8
    public var buttons: UInt8

    public init(x: Int8, y: Int8, horizontal: Int8, vertical: Int8, buttons: UInt8) {
        self.x = x
        self.y = y
        self.horizontal = horizontal
        self.vertical = vertical
        self.buttons = buttons
    }
}
