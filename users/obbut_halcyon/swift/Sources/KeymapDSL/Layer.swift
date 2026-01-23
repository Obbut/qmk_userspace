// Layer definitions for QMK keymaps
// SPDX-License-Identifier: GPL-2.0-or-later

/// Layer identifier matching QMK's layer enum
public struct Layer: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}

// MARK: - Standard Layers

extension Layer {
    /// Default base layer (Colemak-DH)
    public static let `default` = Layer(rawValue: 0)

    /// QWERTY gaming layer
    public static let qwerty = Layer(rawValue: 1)

    /// Lower layer (navigation)
    public static let lower = Layer(rawValue: 2)

    /// Raise layer (symbols and numbers)
    public static let raise = Layer(rawValue: 3)

    /// Function layer (F-keys, RGB, boot)
    public static let function = Layer(rawValue: 4)
}

// MARK: - Layer Definition

/// A complete layer definition containing the layer ID and its key content
public struct LayerDefinition {
    public let layer: Layer
    public let rows: [[Keycode]]

    public init(layer: Layer, rows: [[Keycode]]) {
        self.layer = layer
        self.rows = rows
    }

    /// Flatten all rows into a single keycode array
    public var keycodes: [Keycode] {
        rows.flatMap { $0 }
    }
}

// MARK: - Keymap Container

/// Container for all layer definitions
public struct Keymap {
    public let layers: [LayerDefinition]

    public init(@KeymapBuilder layers: () -> [LayerDefinition]) {
        self.layers = layers()
    }

    /// Get a layer by its identifier
    public subscript(layer: Layer) -> LayerDefinition? {
        layers.first { $0.layer == layer }
    }

    /// Export keymap as a 2D array of UInt16 values for C interop
    public func exportAsArray() -> [[UInt16]] {
        // Sort layers by their raw value
        let sortedLayers = layers.sorted { $0.layer.rawValue < $1.layer.rawValue }
        return sortedLayers.map { layerDef in
            layerDef.keycodes.map { $0.rawValue }
        }
    }
}
