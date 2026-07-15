import QMKKeymapKit
import Testing

/// Exercises direct semantic metadata and user-defined key styles.
@Suite
struct KeyMetadataTests {
    /// Verifies custom metadata needs neither a domain nor catalog registration.
    @Test
    func customSemanticAndStyleBuildKeymap() {
        let keymap = KeymapSpec(id: "example.metadata", layout: Self.layout) {
            Layer(SyntheticLayer.base, name: "Base") {
                Row(
                    Key.a.style(.accent).semantic(.confirm),
                    Key.b.style(.red)
                )
            }
        }

        #expect(keymap.layers[0].keys[0].semantic == .confirm)
        #expect(keymap.layers[0].keys[0].appearance.color == .rgb(1, 2, 3))
        #expect(keymap.layers[0].keys[1].appearance.color == .rgb(255, 0, 0))
    }

    /// The two-key physical layout used by the metadata fixture.
    fileprivate static let layout = LayoutDescriptor(
        id: "example.metadata",
        displayName: "Metadata",
        cMacro: "LAYOUT",
        keyCount: 2,
        matrixRowCount: 1,
        matrixColumnCount: 2,
        matrixMapping: [MatrixPosition(row: 0, column: 0), MatrixPosition(row: 0, column: 1)],
        canvasWidth: 112,
        canvasHeight: 56,
        keys: [
            KeyPlacement(
                matrixPosition: MatrixPosition(row: 0, column: 0),
                geometry: PhysicalKeyPlacement(centerX: 28, centerY: 28)
            ),
            KeyPlacement(
                matrixPosition: MatrixPosition(row: 0, column: 1),
                geometry: PhysicalKeyPlacement(centerX: 84, centerY: 28)
            ),
        ],
        encoders: []
    )
}

fileprivate struct AccentKeyStyle: KeyStyle {
    func makeAppearance(configuration: KeyStyleConfiguration) -> KeyAppearance {
        let color: RGBColor =
            if configuration.semantic == .confirm {
                .rgb(1, 2, 3)
            } else {
                .rgb(3, 2, 1)
            }
        return KeyAppearance(color: color)
    }
}

fileprivate extension KeyStyle where Self == AccentKeyStyle {
    static var accent: AccentKeyStyle { AccentKeyStyle() }
}

fileprivate extension KeySemantic {
    static let confirm = KeySemantic(
        id: "example.confirm",
        legend: "Confirm"
    )
}

fileprivate enum SyntheticLayer {
    static let base = LayerID(rawValue: 0, cIdentifier: "BASE")
}
