// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChangeLogGenerator",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "ChangeLogGenerator", targets: ["ChangeLogGenerator"]),

        .executable(
            name: "changelog",
            targets: ["changelog"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "0.3.1")),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", .upToNextMajor(from: "2.3.0")),

        // testing
        .package(url: "https://github.com/Quick/Quick.git", from: Version(3, 0, 0)),
        .package(url: "https://github.com/Quick/Nimble.git", from: Version(9, 0, 0)),
    ],
    targets: [
        .target(
            name: "ChangeLogGenerator",
            dependencies: []),
        .target(
            name: "changelog",
            dependencies: [
                "ChangeLogGenerator",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "ShellOut",
            ]),

        .testTarget(
            name: "ChangeLogGeneratorTests",
            dependencies: ["ChangeLogGenerator", "Quick", "Nimble"],
            resources: [.process("Resources")]),
    ]
)
