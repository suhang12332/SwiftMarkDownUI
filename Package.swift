// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SwiftMarkDownUI",
    platforms: [
        .macOS(.v14),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SwiftMarkDownUI",
            targets: ["SwiftMarkDownUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui.git", from: "2.0.0"),
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
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            ]),
        .testTarget(
            name: "C_h2mdTests",
            dependencies: ["C_h2md"]),
    ]
)
