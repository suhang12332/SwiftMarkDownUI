// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui.git", from: "2.0.2"),
    ],
    targets: [
        .target(
            name: "SwiftMarkDownUI",
            dependencies: [
                "SwiftSoup",
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            ]),
    ]
)
