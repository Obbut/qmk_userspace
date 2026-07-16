import QMKFirmwareHost
import QMKKeymapKit
import Testing

/// Exercises explicit legends and user-defined key styles.
@Suite
struct KeyMetadataTests {
    @Test
    func legendsUseExplicitIconsWithoutInferringFromLabels() {
        let plain: Legend = "Battery"
        let illustrated = Legend("Battery", icon: .battery)
        let custom = Legend("Profile", icon: .init("person-badge"))

        #expect(StaticStringContent.string(plain.label) == "Battery")
        #expect(plain.icon == nil)
        #expect(illustrated.icon == .battery)
        #expect(illustrated != plain)
        #expect(illustrated.contentID != plain.contentID)
        #expect(StaticStringContent.string(custom.icon!.name) == "person-badge")

        let erased = AnyLegend(id: illustrated.contentID, legend: illustrated)
        #expect(erased.label == "Battery")
        #expect(erased.symbolName == "battery")
    }

    @Test
    func staticSequenceComponentsResolveWithoutArrays() {
        let usesFirstBranch = true
        @KeyRowBuilder func makeSequence() -> some KeySequence {
            Repeat(.transparent, count: 2)
            FunctionKeys(1...3, style: SolidKeyStyle.red)
            if usesFirstBranch {
                Key.a
            } else {
                Key.b
            }
        }
        let row = makeSequence()

        #expect(row.keyCount == 6)
        #expect(row.key(at: 0)?.keycode == Key.transparent.keycode)
        #expect(row.key(at: 1)?.keycode == Key.transparent.keycode)
        #expect(row.key(at: 2)?.keycode == Key.function(1).keycode)
        #expect(row.key(at: 4)?.keycode == Key.function(3).keycode)
        #expect(row.key(at: 5)?.keycode == Key.a.keycode)
        #expect(row.key(at: 6) == nil)
    }

    @Test
    func typedModifiersLayersAndEncodersResolveToABIValues() {
        let encoder = Encoder(0, id: "left") {
            On(SyntheticLayer.base, counterclockwise: .volumeDown, clockwise: .volumeUp)
        }

        #expect(Key.a.withModifiers(.leftCommand).keycode.rawValue == 0x0804)
        #expect(Key.momentary(SyntheticLayer.base).keycode.rawValue == 0x5220)
        #expect(Key.mute.keycode.rawValue == 0x00A8)
        #expect(Key.volumeUp.keycode.rawValue == 0x00A9)
        #expect(Key.volumeDown.keycode.rawValue == 0x00AA)
        #expect(Key.keyboardVolumeUp.keycode.rawValue == 0x0080)
        #expect(Key.keyboardVolumeDown.keycode.rawValue == 0x0081)
        #expect(encoder.encoderCount == 1)
        #expect(encoder.encoder(at: 0)?.index == 0)
        #expect(
            encoder.encoderMapping(onLayer: 0, encoderAt: 0)?.counterclockwise.keycode
                == Key.volumeDown.keycode
        )
    }

    @Test
    func inferredLayerIdentifiersFollowDeclarationOrder() {
        let keymap = KeymapSpec(id: "example.inferred-layers", layout: Self.layout) {
            Layer(name: "Base") {
                Row(.a, .b)
            }
            Layer(name: "Lower") {
                Row(.left, .right)
            }
        }

        #expect(keymap.layers.map(\.id.rawValue) == [0, 1])
    }

    /// Verifies explicit legends and custom styles compose directly on keys.
    @Test
    func customLegendAndStyleBuildKeymap() {
        let keymap = KeymapSpec(id: "example.metadata", layout: Self.layout) {
            Layer(SyntheticLayer.base, name: "Base") {
                Row(
                    Key.a.labeled("Confirm").style(.accent),
                    Key.b.style(.red)
                )
            }
        }

        #expect(
            keymap.layers[0].keys[0].legend.map {
                StaticStringContent.string($0.label)
            } == "Confirm"
        )
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
            if configuration.keycode == Key.a.keycode {
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

fileprivate enum SyntheticLayer {
    static let base = LayerID(rawValue: 0)
}
