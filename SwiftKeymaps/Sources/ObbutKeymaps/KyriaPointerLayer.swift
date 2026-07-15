import QMKKeymapKit

/// The Kyria-only automatic pointer layer.
public struct KyriaPointerLayer: KeymapComponent, Sendable {
    public let keymapElements: [KeymapElement]

    public init() {
        keymapElements = [
            .layer(
                Layer(ObbutLayer.pointer, name: "Pointer") {
                    Row(keys: Self.pointerRowOne)
                    Row(keys: Self.pointerRowTwo)
                    Row(keys: Self.pointerBottomWithModules)
                    Row(keys: Self.transparent(count: 10))
                    Row(keys: Self.transparent(count: 10))
                }
            )
        ]
    }

    fileprivate static var pointerRowOne: [Key] {
        transparent(count: 6)
            + [
                .transparent,
                ObbutKey.pointerSensitivityDown,
                ObbutKey.pointerSensitivityUp,
                ObbutKey.pointerScrollSpeedDown,
                ObbutKey.pointerScrollSpeedUp,
                .transparent,
            ]
    }

    fileprivate static var pointerRowTwo: [Key] {
        transparent(count: 6)
            + [
                ObbutKey.browserBack,
                ObbutKey.pointerLeftClick,
                ObbutKey.pointerRightClick,
                ObbutKey.pointerMiddleClick,
                ObbutKey.browserForward,
                .transparent,
            ]
    }

    fileprivate static var pointerBottomWithModules: [Key] {
        transparent(count: 10)
            + [
                .transparent,
                ObbutKey.pointerScroll,
                ObbutKey.pointerSniper,
                ObbutKey.pointerDragLock,
                .transparent,
                .transparent,
            ]
    }

    fileprivate static func transparent(count: Int) -> [Key] {
        Array(repeating: .transparent, count: count)
    }
}
