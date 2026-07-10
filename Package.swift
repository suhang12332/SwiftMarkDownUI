// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SwiftMarkDownUI",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SwiftMarkDownUI",
            targets: ["SwiftMarkDownUI"]),
        .library(
            name: "C_h2md",
            targets: ["C_h2md"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.6.0"),
    ],
    targets: [
        .target(
            name: "C_h2md",
            path: "Sources/C_h2md",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
            ]),
        .target(
            name: "SwiftMarkDownUI",
            dependencies: [
                "C_h2md",
                .product(name: "Markdown", package: "swift-markdown"),
            ]),
        .testTarget(
            name: "C_h2mdTests",
            dependencies: ["C_h2md"]),
    ]
)
