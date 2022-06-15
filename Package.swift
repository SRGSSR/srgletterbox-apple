// swift-tools-version:5.3

import PackageDescription

struct ProjectSettings {
    static let marketingVersion: String = "8.0.1"
}

let package = Package(
    name: "SRGLetterbox",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12)
    ],
    products: [
        .library(
            name: "SRGLetterbox",
            targets: ["SRGLetterbox"]
        )
    ],
    dependencies: [
        .package(name: "FXReachability", url: "https://github.com/SRGSSR/FXReachability.git", .exact("1.3.2-srg5")),
        .package(name: "OHHTTPStubs", url: "https://github.com/AliSoftware/OHHTTPStubs.git", .upToNextMajor(from: "9.0.0")),
        .package(name: "SRGAnalytics", url: "https://github.com/SRGSSR/srganalytics-apple.git", .upToNextMajor(from: "7.7.0")),
        .package(name: "SRGAppearance", url: "https://github.com/SRGSSR/srgappearance-apple.git", .upToNextMinor(from: "5.1.0")),
        .package(name: "YYWebImage", url: "https://github.com/SRGSSR/YYWebImage.git", .exact("1.0.5-srg3"))
    ],
    targets: [
        .target(
            name: "SRGLetterbox",
            dependencies: [
                "FXReachability",
                .product(name: "SRGAnalyticsDataProvider", package: "SRGAnalytics"),
                "SRGAppearance",
                "YYWebImage"
            ],
            resources: [
                .process("Resources")
            ],
            cSettings: [
                .define("MARKETING_VERSION", to: "\"\(ProjectSettings.marketingVersion)\""),
                .define("NS_BLOCK_ASSERTIONS", to: "1", .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "SRGLetterboxTests",
            dependencies: ["SRGLetterbox", "OHHTTPStubs"],
            cSettings: [
                .headerSearchPath("Private")
            ]
        )
    ]
)
