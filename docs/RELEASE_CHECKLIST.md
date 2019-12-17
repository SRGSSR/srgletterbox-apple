# Release checklist

Use the following checklist when releasing libraries.

### 3rd party dependencies

Release these 3rd party dependencies (forked on SRGSSR github) if needed:

- MAKVONotificationCenter
- libextobjc
- FXReachability
- UICKeyChainStore
- YYWebImage

### SRG SSR libraries

To release an SRG SSR library, perform the following steps sequentially (some steps might be skipped if they do not make sense):

- On _develop_, edit `Cartfile`, `Cartfile.private.common`, `Cartfile.private.public` and `Cartfile.private.proprietary` to point at tagged versions of dependencies only.
- Run `make update`.
- Verify that `Cartfile.resolved`, `Cartfile.resolved.public` and `Cartfile.resolved.proprietary` only contain tagged versions.
- Perform global diff with last release to verify changes.
- Verify version number in project. In particular, bump the minor version number in case of breaking API changes. Commit and push on _develop_.
- Run unit tests successfully in proprietary and public modes.
- Update demo release note JSON. Commit and push on _develop_.
- Start `git-flow release` for the new library version.
- Finish `git-flow release`.
- Bump patch / build version numbers on _develop_ to prepare for the next release.
- Push _master_, _develop_ and tag.
- Close milestone and issues on github.
- Create github release. Use global diff to write release notes.
- Deliver demo on HockeyApp.

The libraries must be released in the order given by the table below, which you can use to keep track of version numbers as you release libraries:

|| SRG Logger | SRG Logger Swift | SRG Appearance | SRG Network | SRG Diagnostics | SRG Media Player | SRG Data Provider | SRG Identity | SRG Content Protection | SRG Content Protection Fake | SRG Analytics | SRG Letterbox | SRG User Data |
|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| **Version** ||||||||||||||


### Letterbox dependency matrix

Update the [Letterbox dependency matrix](https://github.com/SRGSSR/srgletterbox-apple/wiki/Version-matrix) as well.