// swift-tools-version: 6.3

import CompilerPluginSupport
import PackageDescription

/// The complete Swift-first keymap workspace.
let package = Package(
    name: "SwiftQMKKeymaps",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "QMKKeymapKit", targets: ["QMKKeymapKit"]),
        .library(name: "QMKFirmwareRuntime", targets: ["QMKFirmwareRuntime"]),
        .library(name: "ObbutKeymaps", targets: ["ObbutKeymaps"]),
        .library(name: "KyriaFirmware", targets: ["KyriaFirmware"]),
        .library(name: "EloraFirmware", targets: ["EloraFirmware"]),
        .library(name: "Q15Firmware", targets: ["Q15Firmware"]),
        .library(name: "PlanckFirmware", targets: ["PlanckFirmware"]),
        .library(name: "ObbutKeyboardCatalog", targets: ["ObbutKeyboardCatalog"]),
        .library(name: "QMKKeymapRenderer", targets: ["QMKKeymapRenderer"]),
        .executable(name: "qmk-keymapc", targets: ["qmk-keymapc"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            exact: "603.0.2"
        )
    ],
    targets: [
        .macro(
            name: "QMKKeymapMacrosPlugin",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ],
            swiftSettings: strictSwiftSettings
        ),
        .target(
            name: "QMKKeymapKit",
            dependencies: ["QMKKeymapMacrosPlugin"],
            swiftSettings: strictSwiftSettings
        ),
        .target(
            name: "QMKFirmwareRuntime",
            dependencies: ["QMKKeymapKit", "QMKKeymapMacrosPlugin"],
            swiftSettings: strictSwiftSettings
        ),
        .target(
            name: "ObbutKeymaps",
            dependencies: ["QMKKeymapKit", "QMKFirmwareRuntime"],
            swiftSettings: strictSwiftSettings
        ),
        firmwareTarget(name: "KyriaFirmware"),
        firmwareTarget(name: "EloraFirmware"),
        firmwareTarget(name: "Q15Firmware"),
        firmwareTarget(name: "PlanckFirmware"),
        .target(
            name: "ObbutKeyboardCatalog",
            dependencies: [
                "QMKKeymapKit",
                "ObbutKeymaps",
                "KyriaFirmware",
                "EloraFirmware",
                "Q15Firmware",
                "PlanckFirmware",
            ],
            swiftSettings: strictSwiftSettings
        ),
        .target(
            name: "QMKKeymapRenderer",
            dependencies: ["QMKKeymapKit", "QMKFirmwareRuntime"],
            swiftSettings: strictSwiftSettings
        ),
        .executableTarget(
            name: "qmk-keymapc",
            dependencies: [
                "QMKKeymapKit",
                "QMKFirmwareRuntime",
                "ObbutKeyboardCatalog",
            ],
            swiftSettings: strictSwiftSettings
        ),
        .testTarget(
            name: "QMKKeymapKitTests",
            dependencies: [
                "QMKKeymapKit",
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ],
            swiftSettings: strictSwiftSettings
        ),
        .testTarget(
            name: "QMKFirmwareRuntimeTests",
            dependencies: ["QMKFirmwareRuntime"],
            swiftSettings: strictSwiftSettings
        ),
        .testTarget(
            name: "ObbutKeymapsTests",
            dependencies: ["ObbutKeymaps"],
            swiftSettings: strictSwiftSettings
        ),
        .testTarget(
            name: "FirmwareParityTests",
            dependencies: ["ObbutKeyboardCatalog", "QMKFirmwareRuntime"],
            swiftSettings: strictSwiftSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)

/// Strict compiler settings shared by every Swift keymap target.
let strictSwiftSettings: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency"),
    .treatAllWarnings(as: .error),
]

/// Creates one board-specific firmware target.
///
/// - Parameter name: The Swift module name.
/// - Returns: A target that sees the shared Obbut domain and preview renderer.
func firmwareTarget(name: String) -> Target {
    .target(
        name: name,
        dependencies: [
            "ObbutKeymaps",
            .target(name: "QMKKeymapRenderer", condition: .when(platforms: [.macOS])),
        ],
        swiftSettings: strictSwiftSettings
    )
}
