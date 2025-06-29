// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OtosakuStreamingASR",
    platforms: [
        .iOS(.v16),
        .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "OtosakuStreamingASR",
            targets: ["OtosakuStreamingASR"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Otosaku/OtosakuFeatureExtractor-iOS.git", from: "1.0.4"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "OtosakuStreamingASR",
            dependencies: [
                .product(name: "OtosakuFeatureExtractor", package: "OtosakuFeatureExtractor-iOS"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "OtosakuStreamingASRTests",
            dependencies: ["OtosakuStreamingASR"]
        ),
    ]
)
