/// Composes layers, encoders, and reusable components into a typed keymap.
@resultBuilder
public enum KeymapBuilder {
    /// Converts a layer into a builder component.
    ///
    /// - Parameter layer: The layer to include.
    /// - Returns: A single-element builder component.
    public static func buildExpression(_ layer: Layer) -> Keymap {
        Keymap(elements: [.layer(layer)])
    }

    /// Converts an encoder into a builder component.
    ///
    /// - Parameter encoder: The encoder to include.
    /// - Returns: A single-element builder component.
    public static func buildExpression(_ encoder: Encoder) -> Keymap {
        Keymap(elements: [.encoder(encoder)])
    }

    /// Converts a reusable keymap component into a builder component.
    ///
    /// - Parameter component: The reusable component to include.
    /// - Returns: The component's declarations.
    public static func buildExpression<Component: KeymapComponent>(
        _ component: Component
    ) -> Keymap {
        Keymap(elements: component.keymapElements)
    }

    /// Converts an already composed declaration sequence into a builder component.
    ///
    /// - Parameter elements: The declarations to include.
    /// - Returns: The unchanged declarations.
    public static func buildExpression(
        _ elements: [KeymapElement]
    ) -> Keymap {
        Keymap(elements: elements)
    }

    /// Includes declarations produced by another keymap builder.
    ///
    /// - Parameter keymap: The builder result to include.
    /// - Returns: The unchanged builder result.
    public static func buildExpression(_ keymap: Keymap) -> Keymap {
        keymap
    }

    /// Flattens all keymap components.
    ///
    /// - Parameter components: The components in declaration order.
    /// - Returns: Declarations in source order.
    public static func buildBlock(
        _ components: Keymap...
    ) -> Keymap {
        Keymap(elements: components.flatMap(\.elements))
    }

    /// Includes an optional component.
    ///
    /// - Parameter component: The optional component.
    /// - Returns: The component or an empty sequence.
    public static func buildOptional(
        _ component: Keymap?
    ) -> Keymap {
        component ?? Keymap(elements: [])
    }

    /// Selects the first conditional branch.
    ///
    /// - Parameter component: The selected component.
    /// - Returns: The selected declarations.
    public static func buildEither(
        first component: Keymap
    ) -> Keymap {
        component
    }

    /// Selects the second conditional branch.
    ///
    /// - Parameter component: The selected component.
    /// - Returns: The selected declarations.
    public static func buildEither(
        second component: Keymap
    ) -> Keymap {
        component
    }
}
