// swift-tools-version: 6.3

import PackageDescription
import Foundation

let manifestPath = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("KeymapCompanion.manifest")
    .path

let guiLinkerSettings: [LinkerSetting] = [
    .unsafeFlags([
        "-Xlinker", "/MANIFEST:EMBED",
        "-Xlinker", "/MANIFESTINPUT:\(manifestPath)"
    ]),
    .unsafeFlags(["-Xlinker", "/SUBSYSTEM:WINDOWS"], .when(configuration: .release)),
    .unsafeFlags(["-Xlinker", "/ENTRY:mainCRTStartup"], .when(configuration: .release))
]

let package = Package(
    name: "KeymapCompanionWindows",
    products: [
        .executable(name: "KeymapCompanion", targets: ["KeymapCompanion"])
    ],
    dependencies: [
        .package(path: "../../Shared"),
        .package(path: "Dependencies/swift-uwp"),
        .package(path: "Dependencies/swift-windowsappsdk"),
        .package(path: "Dependencies/swift-windowsfoundation"),
        .package(path: "Dependencies/swift-winui")
    ],
    targets: [
        .target(
            name: "CWindowsHID",
            path: "Sources/CWindowsHID",
            publicHeadersPath: "include",
            cSettings: [
                .define("UNICODE"),
                .define("_UNICODE")
            ],
            linkerSettings: [
                .linkedLibrary("hid"),
                .linkedLibrary("setupapi")
            ]
        ),
        .target(
            name: "CWindowsShell",
            path: "Sources/CWindowsShell",
            publicHeadersPath: "include",
            cSettings: [
                .define("UNICODE"),
                .define("_UNICODE")
            ],
            linkerSettings: [
                .linkedLibrary("comdlg32"),
                .linkedLibrary("shell32"),
                .linkedLibrary("user32")
            ]
        ),
        .executableTarget(
            name: "KeymapCompanion",
            dependencies: [
                "CWindowsHID",
                "CWindowsShell",
                .product(name: "KeymapCompanionCore", package: "Shared"),
                .product(name: "UWP", package: "swift-uwp"),
                .product(name: "WinAppSDK", package: "swift-windowsappsdk"),
                .product(name: "WindowsFoundation", package: "swift-windowsfoundation"),
                .product(name: "WinUI", package: "swift-winui")
            ],
            path: "Sources/KeymapCompanion",
            linkerSettings: guiLinkerSettings
        )
    ],
    swiftLanguageModes: [.v6]
)
