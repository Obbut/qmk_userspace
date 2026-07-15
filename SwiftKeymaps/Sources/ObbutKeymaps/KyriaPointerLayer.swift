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
                ObbutKey.pointerSensitivityDown
                ObbutKey.pointerSensitivityUp
                ObbutKey.pointerScrollSpeedDown
                ObbutKey.pointerScrollSpeedUp
                Key.transparent
            }
            Row {
                Repeat(.transparent, count: 6)
                ObbutKey.browserBack
                ObbutKey.pointerLeftClick
                ObbutKey.pointerRightClick
                ObbutKey.pointerMiddleClick
                ObbutKey.browserForward
                Key.transparent
            }
            Row {
                Repeat(.transparent, count: 11)
                ObbutKey.pointerScroll
                ObbutKey.pointerSniper
                ObbutKey.pointerDragLock
                Repeat(.transparent, count: 2)
            }
            Row { Repeat(.transparent, count: 10) }
            Row { Repeat(.transparent, count: 10) }
        }
    }
}
