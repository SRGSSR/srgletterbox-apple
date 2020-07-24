// swift-tools-version:5.3

import PackageDescription

struct ProjectSettings {
    static let marketingVersion: String = "5.0.4"
}

let package = Package(
    name: "SRGLetterbox",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v9),
        .tvOS(.v12)
    ],
    products: [
        .library(
            name: "SRGLetterbox",
            targets: ["SRGLetterbox"]
        ) 
    ],
    dependencies: [
        .package(name: "FXReachability", url: "https://github.com/SRGSSR/FXReachability.git", .branch("feature/spm-support")),
        .package(name: "OHHTTPStubs", url: "https://github.com/AliSoftware/OHHTTPStubs.git", .upToNextMajor(from: "9.0.0")),
        .package(name: "SRGAnalytics", url: "https://github.com/SRGSSR/srganalytics-apple.git", .branch("feature/spm-support")),
        .package(name: "SRGAppearance", url: "https://github.com/SRGSSR/srgappearance-apple.git", .branch("feature/spm-support")),
        .package(name: "YYWebImage", url: "https://github.com/SRGSSR/YYWebImage.git", .branch("feature/spm-support"))
    ],
    targets: [
        .target(
            name: "SRGLetterbox",
            dependencies: [
                "FXReachability",
                .product(name: "SRGAnalyticsDataProvider", package: "SRGAnalytics"),
                "SRGAppearance", "YYWebImage"
            ],
            exclude: [
                "SRGAvailabilityView~ios.xib",
                "SRGAvailabilityView~tvos.xib",
                "SRGContinuousPlaybackView~ios.xib",
                "SRGContinuousPlaybackViewController~tvos.storyboard",
                "SRGControlsBackgroundView~ios.xib",
                "SRGControlsView~ios.xib",
                "SRGCountdownView~ios.xib",
                "SRGCountdownView~tvos.xib",
                "SRGErrorView~ios.xib",
                "SRGErrorView~tvos.xib",
                "SRGLetterboxView~ios.xib",
                "SRGLetterboxSubdivisionCell~ios.xib",
                "SRGNotificationView~ios.xib",
                "SRGNotificationView~tvos.xib"
            ],
            resources: [
                .process("Resources")
            ],
            cSettings: [
                .define("MARKETING_VERSION", to: "\"\(ProjectSettings.marketingVersion)\"")
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
