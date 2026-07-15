// swift-tools-version: 6.3

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SwiftQMKKeymaps",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "QMKKeymapKit", targets: ["QMKKeymapKit"]),
        .library(name: "QMKFirmwareRuntime", targets: ["QMKFirmwareRuntime"]),
        .library(name: "QMKFirmwareHost", targets: ["QMKFirmwareHost"]),
        .library(name: "ObbutKeymaps", targets: ["ObbutKeymaps"]),
        .library(name: "KyriaFirmware", targets: ["KyriaFirmware"]),
        .library(name: "EloraFirmware", targets: ["EloraFirmware"]),
        .library(name: "Q15Firmware", targets: ["Q15Firmware"]),
        .library(name: "PlanckFirmware", targets: ["PlanckFirmware"]),
        .library(name: "ObbutKeyboardCatalog", targets: ["ObbutKeyboardCatalog"]),
        .library(name: "QMKKeymapRenderer", targets: ["QMKKeymapRenderer"]),
        .executable(name: "qmk-keymap-docs", targets: ["qmk-keymap-docs"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            exact: "603.0.0"
        ),
    ],
    targets: [
        .macro(
            name: "QMKFirmwareMacros",
            dependencies: [
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            swiftSettings: strictSwiftSettings
        ),
        .target(
            name: "QMKKeymapKit",
            swiftSettings: strictSwiftSettings
        ),
        .target(
            name: "QMKFirmwareRuntime",
            dependencies: ["QMKKeymapKit", "QMKFirmwareMacros"],
            swiftSettings: strictSwiftSettings
        ),
        .target(
            name: "QMKFirmwareHost",
            dependencies: ["QMKKeymapKit", "QMKFirmwareRuntime"],
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
            name: "ObbutKeyboardLayouts",
            dependencies: [
                "QMKKeymapKit",
                "QMKFirmwareHost",
                "ObbutKeymaps",
            ],
            path: "Sources/ObbutKeyboardCatalog/Layouts",
            swiftSettings: strictSwiftSettings
        ),
        .target(
            name: "ObbutKeyboardCatalog",
            dependencies: [
                "QMKKeymapKit",
                "QMKFirmwareHost",
                "ObbutKeyboardLayouts",
                "ObbutKeymaps",
                "KyriaFirmware",
                "EloraFirmware",
                "Q15Firmware",
                "PlanckFirmware",
            ],
            path: "Sources/ObbutKeyboardCatalog",
            exclude: ["Layouts"],
            sources: ["ObbutKeyboardCatalog.swift"],
            swiftSettings: strictSwiftSettings
        ),
        .target(
            name: "QMKKeymapRenderer",
            dependencies: [
                "QMKKeymapKit",
                "QMKFirmwareRuntime",
                "QMKFirmwareHost",
                "ObbutKeyboardLayouts",
            ],
            swiftSettings: strictSwiftSettings
        ),
        .executableTarget(
            name: "qmk-keymap-docs",
            dependencies: ["ObbutKeyboardCatalog", "QMKFirmwareHost"],
            swiftSettings: strictSwiftSettings
        ),
        .testTarget(
            name: "QMKKeymapKitTests",
            dependencies: ["QMKKeymapKit", "QMKFirmwareHost"],
            swiftSettings: strictSwiftSettings
        ),
        .testTarget(
            name: "QMKFirmwareRuntimeTests",
            dependencies: [
                "QMKFirmwareRuntime",
                "QMKFirmwareMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ],
            swiftSettings: strictSwiftSettings
        ),
        .testTarget(
            name: "ObbutKeymapsTests",
            dependencies: ["ObbutKeymaps"],
            swiftSettings: strictSwiftSettings
        ),
        .testTarget(
            name: "FirmwareParityTests",
            dependencies: [
                "EloraFirmware",
                "KyriaFirmware",
                "ObbutKeyboardCatalog",
                "PlanckFirmware",
                "Q15Firmware",
                "QMKFirmwareHost",
                "QMKFirmwareRuntime",
                "QMKKeymapRenderer",
            ],
            swiftSettings: strictSwiftSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)

let strictSwiftSettings: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency"),
    .treatAllWarnings(as: .error),
]

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
