/// A QMK action with optional semantic and visual metadata.
public struct Key: Sendable {
    /// The keycode emitted at the QMK ABI boundary.
    public let keycode: QMKKeycode

    /// An optional explicit renderer legend.
    public let legend: String?

    /// Optional stable meaning used by renderers and custom behavior.
    public let semantic: KeySemantic?

    /// The portable appearance resolved from this key's style.
    public var appearance: KeyAppearance {
        appearanceProvider?(
            KeyStyleConfiguration(keycode: keycode, semantic: semantic)
        ) ?? .standard
    }

    fileprivate let appearanceProvider: (@Sendable (KeyStyleConfiguration) -> KeyAppearance)?

    /// Creates a key action without additional styling.
    ///
    /// - Parameters:
    ///   - keycode: The QMK keycode expression.
    ///   - legend: An optional explicit renderer legend.
    ///   - semantic: Optional stable meaning for the action.
    public init(
        keycode: QMKKeycode,
        legend: String? = nil,
        semantic: KeySemantic? = nil
    ) {
        self.init(
            keycode: keycode,
            legend: legend,
            semantic: semantic,
            appearanceProvider: nil
        )
    }

    fileprivate init(
        keycode: QMKKeycode,
        legend: String?,
        semantic: KeySemantic?,
        appearanceProvider: (@Sendable (KeyStyleConfiguration) -> KeyAppearance)?
    ) {
        self.keycode = keycode
        self.legend = legend
        self.semantic = semantic
        self.appearanceProvider = appearanceProvider
    }

    /// Returns this key with semantic metadata.
    ///
    /// - Parameter semantic: The stable meaning of the action.
    /// - Returns: A copy carrying the supplied semantic metadata.
    public func semantic(_ semantic: KeySemantic) -> Key {
        Key(
            keycode: keycode,
            legend: legend,
            semantic: semantic,
            appearanceProvider: appearanceProvider
        )
    }

    /// Returns this key using a reusable visual style.
    ///
    /// - Parameter style: The style used by previews, companions, and firmware lighting.
    /// - Returns: A copy carrying the supplied style.
    public func style<Style: KeyStyle>(_ style: Style) -> Key {
        Key(
            keycode: keycode,
            legend: legend,
            semantic: semantic,
            appearanceProvider: { configuration in
                style.makeAppearance(configuration: configuration)
            }
        )
    }

    /// Returns this key with an explicit renderer legend.
    ///
    /// - Parameter legend: The renderer legend.
    /// - Returns: A copy carrying the explicit legend.
    public func labeled(_ legend: String) -> Key {
        Key(
            keycode: keycode,
            legend: legend,
            semantic: semantic,
            appearanceProvider: appearanceProvider
        )
    }

    /// Returns this key wrapped in QMK modifier actions.
    ///
    /// - Parameter modifiers: The modifiers held with the key.
    /// - Returns: The modified key action.
    public func withModifiers(_ modifiers: Modifier...) -> Key {
        let expression = modifiers.reversed().reduce(keycode.cExpression) { expression, modifier in
            "\(modifier.wrapper)(\(expression))"
        }
        let previewValue = keycode.hidValue.map { value in
            value | (modifiers.reduce(UInt16.zero) { $0 | $1.previewMask } << 8)
        }
        return Key(
            keycode: QMKKeycode(cExpression: expression, hidValue: previewValue),
            legend: legend,
            semantic: semantic,
            appearanceProvider: appearanceProvider
        )
    }

    /// Creates a chord in which the final modifier is emitted as the base key.
    ///
    /// - Parameter modifiers: Two or more modifier keys in chord order.
    /// - Returns: A QMK modifier chord.
    public static func chord(_ modifiers: Modifier...) -> Key {
        precondition(modifiers.count >= 2, "A modifier chord needs at least two keys.")
        let base = modifiers[modifiers.count - 1]
        let wrappers = modifiers.dropLast()
        let expression = wrappers.reversed().reduce(base.keycode) { expression, modifier in
            "\(modifier.wrapper)(\(expression))"
        }
        let previewValue =
            UInt16(0x00E0 + modifiers[modifiers.count - 1].previewMask.trailingZeroBitCount)
            | (wrappers.reduce(UInt16.zero) { $0 | $1.previewMask } << 8)
        return Key(keycode: QMKKeycode(cExpression: expression, hidValue: previewValue))
    }

    /// Creates a momentary layer key.
    ///
    /// - Parameter layer: The layer active while the key is held.
    /// - Returns: A QMK `MO` action.
    public static func momentary(_ layer: LayerID) -> Key {
        Key(
            keycode: QMKKeycode(
                cExpression: "MO(\(layer.cIdentifier))",
                hidValue: 0x5220 | UInt16(layer.rawValue)
            )
        )
    }

    /// Creates a layer toggle key.
    ///
    /// - Parameter layer: The layer toggled by the key.
    /// - Returns: A QMK `TG` action.
    public static func toggle(_ layer: LayerID) -> Key {
        Key(
            keycode: QMKKeycode(
                cExpression: "TG(\(layer.cIdentifier))",
                hidValue: 0x5260 | UInt16(layer.rawValue)
            )
        )
    }

    /// Creates a layer-tap key.
    ///
    /// - Parameters:
    ///   - layer: The layer active while the key is held.
    ///   - key: The keycode sent on tap.
    /// - Returns: A QMK `LT` action.
    public static func layerTap(_ layer: LayerID, key: Key) -> Key {
        Key(
            keycode: QMKKeycode(
                cExpression: "LT(\(layer.cIdentifier), \(key.keycode.cExpression))",
                hidValue: key.keycode.hidValue
            )
        )
    }

    /// Creates a modifier-tap key.
    ///
    /// - Parameters:
    ///   - modifiers: The modifier set active while the key is held.
    ///   - key: The keycode sent on tap.
    /// - Returns: A QMK `MT` action.
    public static func modifierTap(_ modifiers: [Modifier], key: Key) -> Key {
        precondition(!modifiers.isEmpty, "A modifier-tap needs at least one modifier.")
        let mask = modifiers.map(\.mask).joined(separator: " | ")
        let previewValue = key.keycode.hidValue.map { value in
            value | (modifiers.reduce(UInt16.zero) { $0 | $1.previewMask } << 8)
        }
        return Key(
            keycode: QMKKeycode(
                cExpression: "MT(\(mask), \(key.keycode.cExpression))",
                hidValue: previewValue
            )
        )
    }

    /// Creates a fork-specific or custom QMK keycode.
    ///
    /// - Parameters:
    ///   - expression: The trusted QMK C expression.
    ///   - legend: An optional renderer legend.
    ///   - semantic: Optional stable meaning for the action.
    /// - Returns: A key action that can be styled or composed further.
    public static func qmk(
        _ expression: String,
        legend: String? = nil,
        semantic: KeySemantic? = nil
    ) -> Key {
        Key(
            keycode: QMKKeycode(cExpression: expression),
            legend: legend,
            semantic: semantic
        )
    }

    /// Creates a fork-specific or custom QMK keycode from a declared token.
    ///
    /// - Parameters:
    ///   - token: The typed host representation of the QMK token.
    ///   - legend: An optional renderer legend.
    ///   - semantic: Optional stable meaning for the action.
    /// - Returns: A key action that can be styled or composed further.
    public static func qmk(
        _ token: QMKToken,
        legend: String? = nil,
        semantic: KeySemantic? = nil
    ) -> Key {
        qmk(token.spelling, legend: legend, semantic: semantic)
    }
}
