// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "AppCenterDistributeOptional",
        platforms: [
        .iOS(.v9),
        .macOS(.v10_10),
        .tvOS(.v11)
    ],
    products: [
        .library(
            name: "AppCenterDistributeOptional",
            targets: ["AppCenterDistributeOptional"]
        )
    ],
    dependencies: [
        .package(name: "AppCenter", url: "https://github.com/microsoft/appcenter-sdk-apple.git", .upToNextMajor(from: "4.4.1"))
    ],
    targets: [
        .target(
            name: "AppCenterDistributeOptional",
            dependencies: [
                .product(name: "AppCenterDistribute", package: "AppCenter", condition: .when(platforms: [.iOS])),
            ]
        )
    ]
)
