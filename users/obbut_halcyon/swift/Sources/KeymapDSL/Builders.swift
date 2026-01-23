// Result builders for SwiftUI-like keymap DSL
// SPDX-License-Identifier: GPL-2.0-or-later

// MARK: - Row Builder

/// Result builder for constructing a single row of keys
@resultBuilder
public struct RowBuilder {
    public static func buildBlock(_ keys: Keycode...) -> [Keycode] {
        keys
    }

    public static func buildExpression(_ key: Keycode) -> Keycode {
        key
    }

    public static func buildArray(_ components: [[Keycode]]) -> [Keycode] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [Keycode]?) -> [Keycode] {
        component ?? []
    }

    public static func buildEither(first component: [Keycode]) -> [Keycode] {
        component
    }

    public static func buildEither(second component: [Keycode]) -> [Keycode] {
        component
    }
}

/// Convenience function to define a row of keys
public func Row(@RowBuilder content: () -> [Keycode]) -> [Keycode] {
    content()
}

// MARK: - Layer Content Builder

/// Result builder for layer content (multiple rows)
@resultBuilder
public struct LayerContentBuilder {
    public static func buildBlock(_ rows: [Keycode]...) -> [[Keycode]] {
        rows
    }

    public static func buildExpression(_ row: [Keycode]) -> [Keycode] {
        row
    }

    public static func buildArray(_ components: [[[Keycode]]]) -> [[Keycode]] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [[Keycode]]?) -> [[Keycode]] {
        component ?? []
    }

    public static func buildEither(first component: [[Keycode]]) -> [[Keycode]] {
        component
    }

    public static func buildEither(second component: [[Keycode]]) -> [[Keycode]] {
        component
    }
}

/// Define a layer with its content
/// Note: Named DefineLayer to avoid conflict with the Layer struct
public func DefineLayer(_ layer: Layer, @LayerContentBuilder content: () -> [[Keycode]]) -> LayerDefinition {
    LayerDefinition(layer: layer, rows: content())
}

// MARK: - Keymap Builder

/// Result builder for collecting multiple layer definitions
@resultBuilder
public struct KeymapBuilder {
    public static func buildBlock(_ layers: LayerDefinition...) -> [LayerDefinition] {
        layers
    }

    public static func buildExpression(_ layer: LayerDefinition) -> LayerDefinition {
        layer
    }

    public static func buildArray(_ components: [[LayerDefinition]]) -> [LayerDefinition] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [LayerDefinition]?) -> [LayerDefinition] {
        component ?? []
    }

    public static func buildEither(first component: [LayerDefinition]) -> [LayerDefinition] {
        component
    }

    public static func buildEither(second component: [LayerDefinition]) -> [LayerDefinition] {
        component
    }
}

// MARK: - Encoder Map Builder

/// Encoder action pair (counter-clockwise and clockwise)
public struct EncoderAction {
    public let counterClockwise: Keycode
    public let clockwise: Keycode

    public init(ccw: Keycode, cw: Keycode) {
        self.counterClockwise = ccw
        self.clockwise = cw
    }
}

/// Encoder map for a layer
public struct EncoderMap {
    public let actions: [EncoderAction]

    public init(actions: [EncoderAction]) {
        self.actions = actions
    }
}

/// Result builder for encoder actions
@resultBuilder
public struct EncoderBuilder {
    public static func buildBlock(_ actions: EncoderAction...) -> EncoderMap {
        EncoderMap(actions: actions)
    }

    public static func buildExpression(_ action: EncoderAction) -> EncoderAction {
        action
    }
}

/// Define encoder behavior
public func Encoder(ccw: Keycode, cw: Keycode) -> EncoderAction {
    EncoderAction(ccw: ccw, cw: cw)
}
