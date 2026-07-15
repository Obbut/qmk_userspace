import QMKFirmwareMacros
import SwiftDiagnostics
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class QMKFirmwareMacroTests: XCTestCase {
    fileprivate let macros: [String: Macro.Type] = [
        "QMKFirmware": QMKFirmwareMacro.self
    ]

    func testExpansionAddsBuildersAndConformance() {
        assertMacroExpansion(
            """
            @QMKFirmware
            public enum ExampleFirmware {
                static let id = "example"
                static let layout = ExampleLayout()
                static let outputName = "example"

                static var keymap: some KeymapDefinition {
                    ExampleLayer()
                }

                static var features: some FirmwareFeatureSet {
                    ExampleFeature()
                }
            }
            """,
            expandedSource: """
            public enum ExampleFirmware {
                static let id = "example"
                static let layout = ExampleLayout()
                static let outputName = "example"
                @_alwaysEmitIntoClient @Keymap

                static var keymap: some KeymapDefinition {
                    ExampleLayer()
                }
                @_alwaysEmitIntoClient @FirmwareFeatureBuilder

                static var features: some FirmwareFeatureSet {
                    ExampleFeature()
                }
            }

            extension ExampleFirmware: QMKFirmware {
            }
            """,
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }

    func testSynthesizesLayerIDFromInferredLayers() {
        assertMacroExpansion(
            """
            @QMKFirmware
            public enum ExampleFirmware {
                static let id = "example"
                static let layout = ExampleLayout()
                static let outputName = "example"

                static var keymap: some KeymapDefinition {
                    Layer(name: "Default") { ExampleRow() }
                    Layer(name: "QWERTY") { ExampleRow() }
                    Layer(name: "Lower", showsHUD: true) { ExampleRow() }
                }

                static var features: some FirmwareFeatureSet {
                    ExampleFeature()
                }
            }
            """,
            expandedSource: """
            public enum ExampleFirmware {
                static let id = "example"
                static let layout = ExampleLayout()
                static let outputName = "example"
                @_alwaysEmitIntoClient @Keymap

                static var keymap: some KeymapDefinition {
                    Layer(name: "Default") { ExampleRow() }
                    Layer(name: "QWERTY") { ExampleRow() }
                    Layer(name: "Lower", showsHUD: true) { ExampleRow() }
                }
                @_alwaysEmitIntoClient @FirmwareFeatureBuilder

                static var features: some FirmwareFeatureSet {
                    ExampleFeature()
                }

                public enum LayerID: UInt8, FirmwareLayerID {
                    case defaultLayer = 0
                    case qwerty = 1
                    case lower = 2
                }
            }

            extension ExampleFirmware: QMKFirmware {
            }
            """,
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }

    func testExplicitLayerIDSuppressesSynthesis() {
        assertMacroExpansion(
            """
            @QMKFirmware
            enum ExampleFirmware {
                typealias LayerID = SharedLayerID
                static let id = "example"
                static let layout = ExampleLayout()
                static let outputName = "example"
                static var keymap: some KeymapDefinition {
                    Layer(name: "Base") { ExampleRow() }
                }
                static var features: some FirmwareFeatureSet { ExampleFeature() }
            }
            """,
            expandedSource: """
            enum ExampleFirmware {
                typealias LayerID = SharedLayerID
                static let id = "example"
                static let layout = ExampleLayout()
                static let outputName = "example"
                @_alwaysEmitIntoClient @Keymap
                static var keymap: some KeymapDefinition {
                    Layer(name: "Base") { ExampleRow() }
                }
                @_alwaysEmitIntoClient @FirmwareFeatureBuilder
                static var features: some FirmwareFeatureSet { ExampleFeature() }
            }

            extension ExampleFirmware: QMKFirmware {
            }
            """,
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }

    func testRejectsNonEnumTarget() {
        assertMacroExpansion(
            """
            @QMKFirmware
            struct ExampleFirmware {}
            """,
            expandedSource: """
            struct ExampleFirmware {}
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@QMKFirmware can only be applied to an enum.",
                    line: 1,
                    column: 1
                )
            ],
            macros: macros
        )
    }

    func testDiagnosesMissingMembers() {
        assertMacroExpansion(
            """
            @QMKFirmware
            enum ExampleFirmware {}
            """,
            expandedSource: """
            enum ExampleFirmware {}

            extension ExampleFirmware: QMKFirmware {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@QMKFirmware requires a static keymap property.",
                    line: 2,
                    column: 6
                ),
                DiagnosticSpec(
                    message: "@QMKFirmware requires a static id property.",
                    line: 2,
                    column: 6
                ),
                DiagnosticSpec(
                    message: "@QMKFirmware requires a static layout property.",
                    line: 2,
                    column: 6
                ),
                DiagnosticSpec(
                    message: "@QMKFirmware requires a static outputName property.",
                    line: 2,
                    column: 6
                ),
                DiagnosticSpec(
                    message: "@QMKFirmware requires a static features property.",
                    line: 2,
                    column: 6
                ),
            ],
            macros: macros
        )
    }

    func testDiagnosesDuplicateKeymapAndRedundantAttribute() {
        assertMacroExpansion(
            """
            @QMKFirmware
            enum ExampleFirmware {
                static let id = "example"
                static let layout = ExampleLayout()
                static let outputName = "example"
                @Keymap static var keymap: some KeymapDefinition { FirstLayer() }
                static var keymap: some KeymapDefinition { SecondLayer() }
                static var features: some FirmwareFeatureSet { ExampleFeature() }
            }
            """,
            expandedSource: """
            enum ExampleFirmware {
                static let id = "example"
                static let layout = ExampleLayout()
                static let outputName = "example"
                @Keymap static var keymap: some KeymapDefinition { FirstLayer() }
                @_alwaysEmitIntoClient @Keymap
                static var keymap: some KeymapDefinition { SecondLayer() }
                @_alwaysEmitIntoClient @FirmwareFeatureBuilder
                static var features: some FirmwareFeatureSet { ExampleFeature() }
            }

            extension ExampleFirmware: QMKFirmware {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "A firmware must declare exactly one static keymap property.",
                    line: 7,
                    column: 5
                )
            ],
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }

    func testDiagnosesRedundantConformance() {
        assertMacroExpansion(
            """
            @QMKFirmware
            enum ExampleFirmware: QMKFirmware {}
            """,
            expandedSource: """
            enum ExampleFirmware: QMKFirmware {}
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Remove the explicit QMKFirmware conformance; @QMKFirmware adds it.",
                    line: 2,
                    column: 6
                )
            ],
            macros: macros
        )
    }

    func testDiagnosesRedundantKeymapBuilder() {
        assertMacroExpansion(
            """
            @QMKFirmware
            enum ExampleFirmware {
                static let id = "example"
                static let layout = ExampleLayout()
                static let outputName = "example"
                @Keymap static var keymap: some KeymapDefinition { ExampleLayer() }
                static var features: some FirmwareFeatureSet { ExampleFeature() }
            }
            """,
            expandedSource: """
            enum ExampleFirmware {
                static let id = "example"
                static let layout = ExampleLayout()
                static let outputName = "example"
                @Keymap static var keymap: some KeymapDefinition { ExampleLayer() }
                @_alwaysEmitIntoClient @FirmwareFeatureBuilder
                static var features: some FirmwareFeatureSet { ExampleFeature() }
            }

            extension ExampleFirmware: QMKFirmware {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Remove @Keymap; @QMKFirmware applies it automatically.",
                    line: 6,
                    column: 5
                )
            ],
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }
}
