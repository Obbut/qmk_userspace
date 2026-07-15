import QMKKeymapKit

/// The Kyria-only automatic pointer layer.
public struct KyriaPointerLayer: KeymapComponent, Sendable {
    /// The keymap domain selected by this component.
    public typealias Domain = ObbutKeymapDomain

    /// The pointer-layer declaration.
    public let keymapElements: [KeymapElement<Domain>]

    /// Creates the complete pointer layer.
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

    /// Pointer row one containing sensitivity and scrolling controls.
    fileprivate static var pointerRowOne: [Key<Domain>] {
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

    /// Pointer row two containing buttons and browser navigation.
    fileprivate static var pointerRowTwo: [Key<Domain>] {
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

    /// Pointer bottom row containing scroll, sniper, and drag lock.
    fileprivate static var pointerBottomWithModules: [Key<Domain>] {
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

    /// Creates a repeated transparent-key sequence.
    fileprivate static func transparent(count: Int) -> [Key<Domain>] {
        Array(repeating: .transparent, count: count)
    }
}
