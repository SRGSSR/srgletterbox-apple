# AppCenterDistributeOptional

This package is here as a workaround to add conditional SPM library to the universal demo target (iOS and tvOS).

The Letterbox demo application needs an optional AppCenter package for:
- iOS: `AppCenterDistribute`
- tvOS: None

Swift 5.3 introduced the [Package Manager Conditional Target Dependencies (SE-0273)](https://github.com/apple/swift-evolution/blob/master/proposals/0273-swiftpm-conditional-target-dependencies.md).

Xcode 13.2.1 can filter platform for frameworks, libraries, and embedded content, but it's only at the link binary with library phase. All SPM dependencies are build before.

 `AppCenterDistribute` is an iOS library only and can't be build for the tvOS platform.
 `AppCenterDistributeOptional` swift package adds this conditional target dependency.


