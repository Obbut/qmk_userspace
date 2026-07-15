import ObbutKeyboardCatalog
import QMKFirmwareRuntime
import Testing

/// Verifies all build outputs, layers, matrices, and encoders remain catalogued.
@Test
func allFirmwareShapesAreStable() {
    let shapes = ObbutKeyboardCatalog.all.map {
        FirmwareShape(
            outputName: $0.outputName,
            layerCount: $0.layers.count,
            matrixRows: $0.layout.matrixRowCount,
            matrixColumns: $0.layout.matrixColumnCount,
            visibleKeyCount: $0.layout.keys.count,
            encoderCount: $0.layout.encoders.count
        )
    }
    #expect(
        shapes == [
            FirmwareShape(
                outputName: "kyria_rev4_obbut",
                layerCount: 6,
                matrixRows: 10,
                matrixColumns: 7,
                visibleKeyCount: 50,
                encoderCount: 1
            ),
            FirmwareShape(
                outputName: "elora_rev2_obbut",
                layerCount: 5,
                matrixRows: 12,
                matrixColumns: 7,
                visibleKeyCount: 62,
                encoderCount: 1
            ),
            FirmwareShape(
                outputName: "keychron_q15_max_ansi_encoder_obbut",
                layerCount: 6,
                matrixRows: 5,
                matrixColumns: 14,
                visibleKeyCount: 66,
                encoderCount: 2
            ),
            FirmwareShape(
                outputName: "zsa_planck_ez_glow_obbut",
                layerCount: 5,
                matrixRows: 8,
                matrixColumns: 6,
                visibleKeyCount: 47,
                encoderCount: 0
            ),
        ]
    )
}

/// Verifies every layer and encoder is dimensionally complete before generation.
@Test
func allFirmwareDefinitionsAreGeneratorReady() {
    for firmware in ObbutKeyboardCatalog.all {
        #expect(firmware.layout.matrixMapping.count == firmware.layout.keyCount)
        #expect(firmware.layers.allSatisfy { $0.keys.count == firmware.layout.keyCount })
        #expect(firmware.encoders.map(\.index).sorted() == firmware.layout.encoders.map(\.index).sorted())
        #expect(
            firmware.encoders.allSatisfy { encoder in
                encoder.mappings.count == firmware.layers.count
            }
        )
    }
}

/// Pins every authored matrix action, semantic, style, and encoder mapping.
@Test
func allAuthoredKeymapsMatchGoldenFingerprints() {
    let fingerprints = Dictionary(
        uniqueKeysWithValues: ObbutKeyboardCatalog.all.map {
            ($0.outputName, authoredKeymapFingerprint($0))
        }
    )

    #expect(
        fingerprints == [
            "kyria_rev4_obbut": 1_046_621_259,
            "elora_rev2_obbut": 2_817_305_777,
            "keychron_q15_max_ansi_encoder_obbut": 326_851_640,
            "zsa_planck_ez_glow_obbut": 4_127_950_778,
        ]
    )
}

/// Computes a deterministic FNV-1a fixture for one complete authored keymap.
///
/// - Parameter firmware: The domain-erased firmware definition.
/// - Returns: A fixture covering every layer key and encoder direction.
private func authoredKeymapFingerprint(_ firmware: AnyFirmware) -> UInt32 {
    var hash: UInt32 = 2_166_136_261

    /// Adds one delimiter-terminated field to the fixture hash.
    func append(_ value: String) {
        for byte in value.utf8 {
            hash ^= UInt32(byte)
            hash &*= 16_777_619
        }
        hash ^= 0xFF
        hash &*= 16_777_619
    }

    for layer in firmware.layers {
        append("layer:\(layer.id.rawValue):\(layer.name)")
        for key in layer.keys {
            append("\(key.cExpression):\(key.semanticID ?? 0):\(key.styleID ?? 0)")
        }
    }
    for encoder in firmware.encoders {
        append("encoder:\(encoder.index):\(encoder.id)")
        for mapping in encoder.mappings {
            append(
                "\(mapping.layer.rawValue):\(mapping.counterclockwise.cExpression):"
                    + "\(mapping.counterclockwise.semanticID ?? 0):"
                    + "\(mapping.counterclockwise.styleID ?? 0)"
            )
            append(
                "\(mapping.clockwise.cExpression):\(mapping.clockwise.semanticID ?? 0):"
                    + "\(mapping.clockwise.styleID ?? 0)"
            )
        }
    }
    return hash
}

/// A concise golden representation of one firmware's structural ABI.
fileprivate struct FirmwareShape: Equatable {
    /// The output filename base.
    let outputName: String

    /// The number of layers.
    let layerCount: Int

    /// The complete matrix row count.
    let matrixRows: Int

    /// The complete matrix column count.
    let matrixColumns: Int

    /// The number of rendered switches.
    let visibleKeyCount: Int

    /// The number of physical encoders.
    let encoderCount: Int
}
