/// A QMK action with optional semantic and visual metadata.
public struct Key: Sendable {
    /// The keycode emitted at the QMK ABI boundary.
    public let keycode: QMKKeycode

    /// An optional explicit renderer legend.
    public let legend: StaticString?

    /// Optional stable meaning used by renderers and custom behavior.
    public let semantic: KeySemantic?

    /// The resolved appearance used by renderers and firmware lighting.
    public let appearance: KeyAppearance

    /// Creates a key action without additional styling.
    ///
    /// - Parameters:
    ///   - keycode: The exact QMK ABI value.
    ///   - legend: An optional explicit renderer legend.
    ///   - semantic: Optional stable meaning for the action.
    ///   - appearance: The resolved visual appearance.
    public init(
        keycode: QMKKeycode,
        legend: StaticString? = nil,
        semantic: KeySemantic? = nil,
        appearance: KeyAppearance = .standard
    ) {
        self.keycode = keycode
        self.legend = legend
        self.semantic = semantic
        self.appearance = appearance
    }

    /// Returns this key with semantic metadata.
    public func semantic(_ semantic: KeySemantic) -> Key {
        Key(
            keycode: keycode,
            legend: legend,
            semantic: semantic,
            appearance: appearance
        )
    }

    /// Returns this key using a reusable visual style.
    public func style<Style: KeyStyle>(_ style: Style) -> Key {
        Key(
            keycode: keycode,
            legend: legend,
            semantic: semantic,
            appearance: style.makeAppearance(
                configuration: KeyStyleConfiguration(keycode: keycode, semantic: semantic)
            )
        )
    }

    /// Returns this key with an explicit renderer legend.
    public func labeled(_ legend: StaticString) -> Key {
        Key(
            keycode: keycode,
            legend: legend,
            semantic: semantic,
            appearance: appearance
        )
    }

    /// Returns this key wrapped in one QMK modifier action.
    public func withModifiers(_ first: Modifier) -> Key {
        withModifierMask(first.qmkMask)
    }

    /// Returns this key wrapped in two QMK modifier actions.
    public func withModifiers(_ first: Modifier, _ second: Modifier) -> Key {
        withModifierMask(first.qmkMask | second.qmkMask)
    }

    /// Returns this key wrapped in three QMK modifier actions.
    public func withModifiers(
        _ first: Modifier,
        _ second: Modifier,
        _ third: Modifier
    ) -> Key {
        withModifierMask(first.qmkMask | second.qmkMask | third.qmkMask)
    }

    /// Creates a two-modifier chord whose final modifier is the base key.
    public static func chord(_ first: Modifier, _ second: Modifier) -> Key {
        modifiedModifierKey(base: second, wrappers: first.qmkMask)
    }

    /// Creates a three-modifier chord whose final modifier is the base key.
    public static func chord(
        _ first: Modifier,
        _ second: Modifier,
        _ third: Modifier
    ) -> Key {
        modifiedModifierKey(base: third, wrappers: first.qmkMask | second.qmkMask)
    }

    /// Creates a momentary layer key.
    public static func momentary<ID: FirmwareLayerID>(_ layer: ID) -> Key {
        Key(keycode: QMKKeycode(rawValue: 0x5220 | UInt16(layer.rawValue)))
    }

    /// Creates a layer toggle key.
    public static func toggle<ID: FirmwareLayerID>(_ layer: ID) -> Key {
        Key(keycode: QMKKeycode(rawValue: 0x5260 | UInt16(layer.rawValue)))
    }

    /// Creates a layer-tap key.
    public static func layerTap<ID: FirmwareLayerID>(_ layer: ID, key: Key) -> Key {
        let value = UInt16(0x4000)
            | (UInt16(layer.rawValue & 0x0F) << 8)
            | (key.keycode.rawValue & 0x00FF)
        return Key(keycode: QMKKeycode(rawValue: value))
    }

    /// Creates a modifier-tap key with one modifier.
    public static func modifierTap(_ modifier: Modifier, key: Key) -> Key {
        modifierTap(mask: modifier.qmkMask, key: key)
    }

    /// Creates a modifier-tap key with two modifiers.
    public static func modifierTap(
        _ first: Modifier,
        _ second: Modifier,
        key: Key
    ) -> Key {
        modifierTap(mask: first.qmkMask | second.qmkMask, key: key)
    }

    /// Creates a modifier-tap key with three modifiers.
    public static func modifierTap(
        _ first: Modifier,
        _ second: Modifier,
        _ third: Modifier,
        key: Key
    ) -> Key {
        modifierTap(mask: first.qmkMask | second.qmkMask | third.qmkMask, key: key)
    }

    /// Creates a typed fork-specific or custom QMK keycode.
    public static func qmk(
        _ keycode: QMKKeycode,
        legend: StaticString? = nil,
        semantic: KeySemantic? = nil
    ) -> Key {
        Key(keycode: keycode, legend: legend, semantic: semantic)
    }

    fileprivate func withModifierMask(_ mask: UInt16) -> Key {
        Key(
            keycode: QMKKeycode(
                rawValue: ((mask & 0x1F) << 8) | (keycode.rawValue & 0x00FF)
            ),
            legend: legend,
            semantic: semantic,
            appearance: appearance
        )
    }

    fileprivate static func modifiedModifierKey(base: Modifier, wrappers: UInt16) -> Key {
        Key(
            keycode: QMKKeycode(
                rawValue: ((wrappers & 0x1F) << 8) | base.keycode
            )
        )
    }

    fileprivate static func modifierTap(mask: UInt16, key: Key) -> Key {
        Key(
            keycode: QMKKeycode(
                rawValue: 0x2000
                    | ((mask & 0x1F) << 8)
                    | (key.keycode.rawValue & 0x00FF)
            )
        )
    }
}
