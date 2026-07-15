/// A QMK action whose semantics and style belong to one keymap domain.
public struct Key<Domain: KeymapDomain>: Equatable, Sendable {
    /// The keycode emitted at the QMK ABI boundary.
    public let keycode: QMKKeycode

    /// An optional explicit renderer legend.
    public let legend: String?

    /// An optional domain-owned semantic identifier.
    public let semanticID: Domain.Semantic?

    /// An optional domain-owned style identifier.
    public let styleID: Domain.Style?

    /// Creates a domain-typed key.
    ///
    /// - Parameters:
    ///   - keycode: The QMK keycode expression.
    ///   - legend: An optional explicit renderer legend.
    ///   - semanticID: An optional domain-owned semantic identifier.
    ///   - styleID: An optional domain-owned style identifier.
    public init(
        keycode: QMKKeycode,
        legend: String? = nil,
        semanticID: Domain.Semantic? = nil,
        styleID: Domain.Style? = nil
    ) {
        self.keycode = keycode
        self.legend = legend
        self.semanticID = semanticID
        self.styleID = styleID
    }

    /// Returns this key with an explicit semantic identifier.
    ///
    /// - Parameter semanticID: A semantic from this key's domain.
    /// - Returns: A copy carrying the semantic identifier.
    public func semantic(_ semanticID: Domain.Semantic) -> Key {
        Key(
            keycode: keycode,
            legend: legend,
            semanticID: semanticID,
            styleID: styleID
        )
    }

    /// Returns this key with an explicit visual style.
    ///
    /// - Parameter styleID: A style from this key's domain.
    /// - Returns: A copy carrying the style identifier.
    public func style(_ styleID: Domain.Style) -> Key {
        Key(
            keycode: keycode,
            legend: legend,
            semanticID: semanticID,
            styleID: styleID
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
            semanticID: semanticID,
            styleID: styleID
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
            semanticID: semanticID,
            styleID: styleID
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
        let previewValue = UInt16(0x00E0 + modifiers[modifiers.count - 1].previewMask.trailingZeroBitCount)
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

    /// Creates an escape-tap Aerospace modifier action.
    ///
    /// - Returns: A QMK modifier-tap action matching the Q15 behavior.
    public static var escapeAerospace: Key {
        modifierTap([.leftControl, .leftCommand, .rightOption], key: .escape)
    }

    /// Creates a fork-specific or custom QMK keycode.
    ///
    /// - Parameters:
    ///   - expression: The trusted QMK C expression.
    ///   - legend: The renderer legend.
    ///   - semanticID: An optional domain-owned semantic identifier.
    ///   - styleID: An optional domain-owned style identifier.
    /// - Returns: A domain-typed key action.
    public static func qmk(
        _ expression: String,
        legend: String? = nil,
        semantic semanticID: Domain.Semantic? = nil,
        style styleID: Domain.Style? = nil
    ) -> Key {
        Key(
            keycode: QMKKeycode(cExpression: expression),
            legend: legend,
            semanticID: semanticID,
            styleID: styleID
        )
    }
}
