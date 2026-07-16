import QMKKeymapKit

/// The Kyria-only automatic pointer layer.
public struct KyriaPointerLayer: KeymapComponent, Sendable {
    public init() {}

    @_alwaysEmitIntoClient
    @inline(__always)
    @Keymap
    public var body: some KeymapDefinition {
        Layer(ObbutLayer.pointer, name: "Pointer") {
            Row {
                Repeat(.transparent, count: 7)
                Key.pointerSensitivityDown
                Key.pointerSensitivityUp
                Key.pointerScrollSpeedDown
                Key.pointerScrollSpeedUp
                Key.transparent
            }
            Row {
                Repeat(.transparent, count: 6)
                Key.browserBack
                Key.pointerLeftClick
                Key.pointerRightClick
                Key.pointerMiddleClick
                Key.browserForward
                Key.transparent
            }
            Row {
                Repeat(.transparent, count: 11)
                Key.pointerScroll
                Key.pointerSniper
                Key.pointerDragLock
                Repeat(.transparent, count: 2)
            }
            Row { Repeat(.transparent, count: 10) }
            Row { Repeat(.transparent, count: 10) }
        }
    }
}
