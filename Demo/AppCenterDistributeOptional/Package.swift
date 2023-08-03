// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "AppCenterDistributeOptional",
        platforms: [
        .iOS(.v11),
        .macOS(.v10_13),
        .tvOS(.v11)
    ],
    products: [
        .library(
            name: "AppCenterDistributeOptional",
            targets: ["AppCenterDistributeOptional"]
        )
    ],
    dependencies: [
        .package(name: "AppCenter", url: "https://github.com/microsoft/appcenter-sdk-apple.git", .upToNextMajor(from: "5.0.3"))
    ],
    targets: [
        .target(
            name: "AppCenterDistributeOptional",
            dependencies: [
                .product(name: "AppCenterDistribute", package: "AppCenter", condition: .when(platforms: [.iOS]))
            ]
        )
    ]
)
