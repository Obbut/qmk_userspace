import ObbutKeyboardCatalog
import QMKFirmwareHost
import XCTest

/// Verifies all build outputs, layers, matrices, and encoders remain catalogued.
final class FirmwareCatalogTests: XCTestCase {
func testAllFirmwareShapesAreStable() {
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
    XCTAssertEqual(
        shapes,
        [
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

/// Verifies every layer and encoder is dimensionally complete for host traversal.
func testAllFirmwareDefinitionsAreComplete() {
    for firmware in ObbutKeyboardCatalog.all {
        XCTAssertEqual(firmware.layout.matrixMapping.count, firmware.layout.keyCount)
        XCTAssertTrue(firmware.layers.allSatisfy { $0.keys.count == firmware.layout.keyCount })
        XCTAssertEqual(
            firmware.encoders.map(\.index).sorted(),
            firmware.layout.encoders.map(\.index).sorted()
        )
        XCTAssertTrue(
            firmware.encoders.allSatisfy { encoder in
                encoder.mappings.count == firmware.layers.count
            }
        )
    }
}

/// Pins the two-unit Planck spacebar between its adjacent bottom-row keys.
func testPlanckSpacebarGeometryIsContiguous() throws {
    let planck = try XCTUnwrap(
        ObbutKeyboardCatalog.all.first { $0.outputName == "zsa_planck_ez_glow_obbut" }
    )
    let bottomRow = planck.layout.keys.suffix(11)
    let leftKey = bottomRow[bottomRow.index(bottomRow.startIndex, offsetBy: 4)].geometry
    let spacebar = bottomRow[bottomRow.index(bottomRow.startIndex, offsetBy: 5)].geometry
    let rightKey = bottomRow[bottomRow.index(bottomRow.startIndex, offsetBy: 6)].geometry
    let halfUnit = 28.0

    XCTAssertEqual(spacebar.width, 2)
    XCTAssertEqual(
        leftKey.centerX + leftKey.width * halfUnit,
        spacebar.centerX - spacebar.width * halfUnit
    )
    XCTAssertEqual(
        spacebar.centerX + spacebar.width * halfUnit,
        rightKey.centerX - rightKey.width * halfUnit
    )
}

/// Pins every matrix action, semantic, style, and encoder mapping.
func testAllKeymapsMatchGoldenFingerprints() {
    let fingerprints = Dictionary(
        uniqueKeysWithValues: ObbutKeyboardCatalog.all.map {
            ($0.outputName, keymapFingerprint($0))
        }
    )

    XCTAssertEqual(
        fingerprints,
        [
            "kyria_rev4_obbut": 2_686_837_719,
            "elora_rev2_obbut": 469_198_795,
            "keychron_q15_max_ansi_encoder_obbut": 318_052_838,
            "zsa_planck_ez_glow_obbut": 2_308_720_423,
        ]
    )
}
}

/// Computes a deterministic FNV-1a fixture for a firmware definition.
///
/// - Parameter firmware: The resolved firmware definition.
/// - Returns: A fixture covering every layer key and encoder direction.
private func keymapFingerprint(_ firmware: AnyFirmware) -> UInt32 {
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
            append("\(key.keycode):\(key.semanticID ?? 0):\(key.styleID)")
        }
    }
    for encoder in firmware.encoders {
        append("encoder:\(encoder.index):\(encoder.id)")
        for mapping in encoder.mappings {
            append(
                "\(mapping.layer.rawValue):\(mapping.counterclockwise.keycode):"
                    + "\(mapping.counterclockwise.semanticID ?? 0):"
                    + "\(mapping.counterclockwise.styleID)"
            )
            append(
                "\(mapping.clockwise.keycode):\(mapping.clockwise.semanticID ?? 0):"
                    + "\(mapping.clockwise.styleID)"
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
