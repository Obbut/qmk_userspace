// swift-tools-version: 6.3

import PackageDescription

/// The shared keymap-companion package manifest.
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
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-dependencies",
            exact: "1.12.0"
        ),
        // 1.10+ contains documentation symlinks that cannot be checked out on
        // stock Windows installations without enabling Developer Mode.
        .package(
            url: "https://github.com/pointfreeco/xctest-dynamic-overlay",
            exact: "1.9.0"
        ),
        // 1.1+ assumes pthreads on every non-Darwin platform. 1.0.3 keeps
        // Combine-only scheduler code excluded on native Windows.
        .package(
            url: "https://github.com/pointfreeco/combine-schedulers",
            exact: "1.0.3"
        ),
    ],
    targets: [
        .target(
            name: "KeymapCompanionCore",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(
                    name: "IssueReporting",
                    package: "xctest-dynamic-overlay",
                    condition: .when(platforms: [.windows])
                ),
                .product(
                    name: "CombineSchedulers",
                    package: "combine-schedulers",
                    condition: .when(platforms: [.windows])
                ),
            ],
            path: ".",
            exclude: ["KeymapCompanionCoreTests"],
            sources: [
                "KeymapProtocol",
                "KeymapCompanionCore",
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error)
            ]
        ),
        .testTarget(
            name: "KeymapCompanionCoreTests",
            dependencies: ["KeymapCompanionCore"],
            path: "KeymapCompanionCoreTests",
            swiftSettings: [
                .treatAllWarnings(as: .error)
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
