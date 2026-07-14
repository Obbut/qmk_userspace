// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "KeymapCompanionShared",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "KeymapCompanionCore",
            targets: ["KeymapCompanionCore"]
        )
    ],
    targets: [
        .target(
            name: "KeymapCompanionCore",
            path: ".",
            exclude: ["KeymapCompanionCoreTests"],
            sources: [
                "KeymapProtocol",
                "KeymapCompanionCore"
            ]
        ),
        .testTarget(
            name: "KeymapCompanionCoreTests",
            dependencies: ["KeymapCompanionCore"],
            path: "KeymapCompanionCoreTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
