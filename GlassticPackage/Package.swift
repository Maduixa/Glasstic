// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GlassticFeature",
    platforms: [.iOS(.v26)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "GlassticFeature",
            targets: ["GlassticFeature"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "GlassticFeature",
            exclude: ["CLAUDE.md", "Glasstic", "GlassticPackage"]
        ),
        .testTarget(
            name: "GlassticFeatureTests",
            dependencies: [
                "GlassticFeature"
            ]
        ),
    ]
)
