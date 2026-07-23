// swift-tools-version: 6.3

import Foundation
import PackageDescription

/// The absolute path to the application manifest embedded by the linker.
let manifestPath = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("KeymapCompanion.manifest")
    .path

/// The absolute path to the compiled Windows application resources.
let applicationResourcesPath = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent(".build/KeymapCompanion.res")
    .path

/// The linker settings required for a windowed, manifested Windows application.
let guiLinkerSettings: [LinkerSetting] = [
    .unsafeFlags([
        "-Xlinker", "/MANIFEST:EMBED",
        "-Xlinker", "/MANIFESTINPUT:\(manifestPath)",
    ]),
    .unsafeFlags(["-Xlinker", applicationResourcesPath]),
    .unsafeFlags(["-Xlinker", "/SUBSYSTEM:WINDOWS"]),
    .unsafeFlags(["-Xlinker", "/ENTRY:mainCRTStartup"]),
]

/// The Windows keymap-companion package manifest.
let package = Package(
    name: "KeymapCompanionWindows",
    products: [
        .executable(name: "KeymapCompanion", targets: ["KeymapCompanion"])
    ],
    dependencies: [
        .package(path: "../../Shared"),
        .package(
            url: "https://github.com/pointfreeco/swift-dependencies",
            exact: "1.12.0"
        ),
        .package(path: "Dependencies/swift-uwp"),
        .package(path: "Dependencies/swift-windowsappsdk"),
        .package(path: "Dependencies/swift-windowsfoundation"),
        .package(path: "Dependencies/swift-winui"),
    ],
    targets: [
        .target(
            name: "CWindowsHID",
            path: "Sources/CWindowsHID",
            publicHeadersPath: "include",
            cSettings: [
                .define("UNICODE"),
                .define("_UNICODE"),
            ],
            linkerSettings: [
                .linkedLibrary("hid"),
                .linkedLibrary("setupapi"),
            ]
        ),
        .target(
            name: "CWindowsShell",
            path: "Sources/CWindowsShell",
            publicHeadersPath: "include",
            cSettings: [
                .define("UNICODE"),
                .define("_UNICODE"),
            ],
            linkerSettings: [
                .linkedLibrary("comdlg32"),
                .linkedLibrary("shell32"),
                .linkedLibrary("user32"),
            ]
        ),
        .executableTarget(
            name: "KeymapCompanion",
            dependencies: [
                "CWindowsHID",
                "CWindowsShell",
                .product(name: "KeymapCompanionCore", package: "Shared"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "UWP", package: "swift-uwp"),
                .product(name: "WinAppSDK", package: "swift-windowsappsdk"),
                .product(name: "WindowsFoundation", package: "swift-windowsfoundation"),
                .product(name: "WinUI", package: "swift-winui"),
            ],
            path: "Sources/KeymapCompanion",
            swiftSettings: [
                .treatAllWarnings(as: .error)
            ],
            linkerSettings: guiLinkerSettings
        ),
        .testTarget(
            name: "KeymapCompanionTests",
            dependencies: ["KeymapCompanion"],
            path: "Tests/KeymapCompanionTests",
            swiftSettings: [
                .treatAllWarnings(as: .error)
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
