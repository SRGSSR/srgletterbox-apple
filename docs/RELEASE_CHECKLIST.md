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

- On _develop_, edit `Package.swift` to point at `.upToNextMinor(from:)` tagged versions of dependencies.
- If there is a demo also ensure its dependencies (SPM, Carthage or CocoaPods depending on the kind of integration required) are also set to official tags.
- Update packages for all projects (main framework of course, but also demo and test projects if they exist). Wait until package dependencies have been updated and build each project to ensure everything compiles successfully. Then commit the changes.
- Run swift linter and commit, if needed. `swiftlint --fix && swiftlint`.
- Perform a global diff with the last release to verify changes.
- Bump the library (and demo project, if any) versions in `Package.swift` (respectively `Demo.xcconfig`). Please observe  [semantic versioning](https://semver.org) rules, as well as our [additional conventions](https://confluence.srg.beecollaboration.com/pages/viewpage.action?pageId=25624796):
    - If the deployment target of the library is changed, at least its minor version number must be updated.
    - If a **direct or transitive** dependency of the library was updated to a new major version, the library itself must at least have its minor version number updated.
- Commit the version update and push to _develop_.
- Run the demo, if any, on iOS (and tvOS if supported).
- Run unit tests successfully, on iOS and tvOS.
- Update the demo release note JSON, if any. Commit and push on _develop_.
- Start `git-flow release` for the new library version.
- Finish `git-flow release`.
- Bump the patch / build version numbers on _develop_ to prepare for the next release.
- Push _master_, _develop_ and tag.
- Close the milestone and issues on github.
- Create the github release. Use a global diff to write release notes.
- Deliver demos on AppCenter / TestFlight from _master_, if any.

The libraries must be released in the order given by the table below, which you can use to keep track of version numbers as you release libraries:

|| SRG Logger | SRG Appearance | SRG Network | SRG Diagnostics | SRG Media Player | SRG Data Provider | SRG Identity | SRG Content Protection | SRG Analytics | SRG Letterbox | SRG User Data |
|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| **Version** ||||||||||||

### SRG Letterbox dependency matrix

Update the [Letterbox dependency matrix](https://github.com/SRGSSR/srgletterbox-apple/wiki/Version-matrix) with corresponding version information.

### SRG Letterbox Demo

With each release of the Letterbox library an iOS and tvOS demo application is released as well. The _application build number_ is used to have a unique application build. Bumping the demo build number on _develop_ is therefore a required step after a new library version has been released, as described [above](#srg-ssr-libraries).

A new Letterbox demo application can also be delivered if a **direct or transitive** dependency of the library was updated to a **new patch version**. The Letterbox library version does not change. Perform the following steps sequentially:

- Start `git-flow hotfix` for the new demo version (e.g. with `demo` as hotfix name).
- Update SPM dependencies in the Demo project and in the `Package.swift` file.
- Bump the demo build number on the hotfix branch to prepare for the next demo release (`Demo.xcconfig`).
- Update the demo release note JSON.
- Finish `git-flow hotfix` for the hotfix branch.
- Bump the demo build number on _develop_ to prepare for the next demo release (`Demo.xcconfig`).
- **DON'T push** the new `demo` tag. Remove it locally.
- Push _master_ and _develop_.
- Deliver demos on AppCenter / TestFlight from _master_.
