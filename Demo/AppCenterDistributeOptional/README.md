# AppCenterDistributeOptional

This package is a workaround to conditionally add the `AppCenterDistribute` SPM library to the universal Letterbox demo target (iOS and tvOS). The Letterbox demo application namely needs `AppCenterDistribute` but this dependency is only provided for iOS.

Xcode can filter frameworks, libraries and embedded content per platform (target _General_ settings) but this affects only the linker phase. All SPM dependencies are always built anyway, which fails for a universal target if one of its products is not available for all platforms supported by the target.
 
Fortunately Swift 5.3 introduced the [Package Manager Conditional Target Dependencies (SE-0273)](https://github.com/apple/swift-evolution/blob/master/proposals/0273-swiftpm-conditional-target-dependencies.md). This package uses conditional modifiers to correctly expose the `AppCenterDistribute` to the Letterbox demo universal target, in a way that allows it to compile successfully.


