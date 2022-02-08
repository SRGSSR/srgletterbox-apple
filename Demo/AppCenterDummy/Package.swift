// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "AppCenterDummy",
        platforms: [
        .iOS(.v9),
        .macOS(.v10_10),
        .tvOS(.v11)
    ],
    products: [
        .library(
            name: "AppCenterDummy",
            targets: ["AppCenterDummy"]),
    ],
    dependencies: [
        .package(name: "AppCenter", url: "https://github.com/microsoft/appcenter-sdk-apple.git", .upToNextMajor(from: "4.4.1")),
    ],
    targets: [
        .target(
            name: "AppCenterDummy",
            dependencies: [
                .product(name: "AppCenterCrashes", package: "AppCenter"),
                .product(name: "AppCenterDistribute", package: "AppCenter", condition: .when(platforms: [.iOS])),
            ]
        )
    ]
)
