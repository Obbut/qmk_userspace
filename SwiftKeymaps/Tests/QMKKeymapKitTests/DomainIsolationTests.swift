import QMKKeymapKit
import Testing

/// Verifies the reusable framework can describe a non-Obbut domain.
@Test
func syntheticDomainBuildsTypedKeymap() {
    let layout = LayoutDescriptor(
        id: "example.synthetic",
        displayName: "Synthetic",
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
    let keymap = KeymapSpec<SyntheticDomain>(id: "example.synthetic", layout: layout) {
        Layer(SyntheticLayer.base, name: "Base") {
            Row(Key<SyntheticDomain>.a.semantic(.confirm), .b.style(.accent))
        }
    }

    #expect(keymap.layers.count == 1)
    #expect(keymap.layers[0].keys[0].semanticID == .confirm)
    #expect(keymap.layers[0].keys[1].styleID == .accent)
}

/// A non-Obbut semantic vocabulary used only to prove domain isolation.
fileprivate enum SyntheticSemantic: UInt16, KeySemanticID {
    /// A synthetic confirmation action.
    case confirm = 42
}

/// A non-Obbut style vocabulary used only to prove domain isolation.
fileprivate enum SyntheticStyle: UInt16, KeyStyleID {
    /// A synthetic accent.
    case accent = 7
}

/// A non-Obbut domain used to verify framework isolation.
fileprivate enum SyntheticDomain: KeymapDomain {
    /// The semantic catalog type.
    typealias Semantics = SemanticCatalogValue<SyntheticSemantic>

    /// The style catalog type.
    typealias Styles = StyleCatalogValue<SyntheticStyle>

    /// The synthetic semantic catalog.
    @SemanticCatalogBuilder
    static var semantics: Semantics {
        QMKKeymapKit.Semantic(SyntheticSemantic.confirm, legend: "Confirm")
    }

    /// The synthetic style catalog.
    @StyleCatalogBuilder
    static var styles: Styles {
        QMKKeymapKit.Style(SyntheticStyle.accent, color: .rgb(1, 2, 3))
    }
}

/// Synthetic layer identifiers.
fileprivate enum SyntheticLayer {
    /// The only layer.
    static let base = LayerID(rawValue: 0, cIdentifier: "BASE")
}
