# Release checklist

Use the following checklist when releasing libraries.

### 3rd party dependencies

Release these 3rd party dependencies (forked on SRGSSR github) if needed:

- [ComScore](https://github.com/SRGSSR/ComScore-xcframework-apple)
- [FXReachability](https://github.com/SRGSSR/FXReachability)
- [libextobjc](https://github.com/SRGSSR/libextobjc)
- [MAKVONotificationCenter](https://github.com/SRGSSR/MAKVONotificationCenter)
- [TCCore](https://github.com/SRGSSR/TCCore-xcframework-apple)
- [TCSDK](https://github.com/SRGSSR/TCSDK-xcframework-apple)
- [YYWebImage](https://github.com/SRGSSR/YYWebImage)

### SRG SSR libraries

To release an SRG SSR library, perform the following steps sequentially (some steps might be skipped if they do not make sense):

- On _develop_, edit `Package.swift` to point at `.upToNextMinor(from:)` tagged versions of dependencies. If there is a demo, also ensure its dependencies (SPM, Carthage or CocoaPods depending on the kind of integration required) are also official tags.
- Update packages for all projects (main framework of course, but also demo and test projects if they exist). Wait until package dependencies have been updated and build each project to ensure this works. The commit the changes.
- Perform global diff with last release to verify changes.
- Verify version numbers in `Package.swift` and in the demo project `xcconfig` (if any). Bump them consistently according to [semantic versioning rules](https://semver.org) if needed. Commit and push on _develop_.
- Run the demo, if any, on iOS (and tvOS if supported).
- Run unit tests successfully, on iOS and tvOS.
- Update demo release note JSON, if any. Commit and push on _develop_.
- Start `git-flow release` for the new library version.
- Finish `git-flow release`.
- Bump patch / build version numbers on _develop_ to prepare for the next release.
- Push _master_, _develop_ and tag.
- Close milestone and issues on github.
- Create github release. Use global diff to write release notes.
- Deliver demo on AppCenter.

The libraries must be released in the order given by the table below, which you can use to keep track of version numbers as you release libraries:

|| SRG Logger | SRG Appearance | SRG Network | SRG Diagnostics | SRG Media Player | SRG Data Provider | SRG Identity | SRG Content Protection | SRG Analytics | SRG Letterbox | SRG User Data |
|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| **Version** ||||||||||||


### Letterbox dependency matrix

Update the [Letterbox dependency matrix](https://github.com/SRGSSR/srgletterbox-apple/wiki/Version-matrix) as well.