// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StripTags",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        // Library product
        .library(
            name: "StripTags",
            targets: ["StripTags"]),
        // Executable CLI product
        .executable(
            name: "strip-tags",
            targets: ["StripTagsCLI"]),
    ],
    dependencies: [
        // SwiftSoup for HTML parsing (similar to BeautifulSoup)
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.0"),
        // ArgumentParser for CLI (similar to Click)
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        // Library target
        .target(
            name: "StripTags",
            dependencies: ["SwiftSoup"]),
        // CLI executable target
        .executableTarget(
            name: "StripTagsCLI",
            dependencies: [
                "StripTags",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        // Test target
        .testTarget(
            name: "StripTagsTests",
            dependencies: ["StripTags"]),
    ]
)
