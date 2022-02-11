fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios tests

```sh
[bundle exec] fastlane ios tests
```

Run library tests

### ios iOSnightly

```sh
[bundle exec] fastlane ios iOSnightly
```

Build a new iOS nightly demo on App Center

### ios tvOSnightly

```sh
[bundle exec] fastlane ios tvOSnightly
```

Build a new tvOS nightly demo on AppStore Connect and wait build processing.

### ios tvOSnightlyDSYMs

```sh
[bundle exec] fastlane ios tvOSnightlyDSYMs
```

Send latest tvOS nightly dSYMs to App Center, with optional 'version' or 'min_version' parameters.

### ios iOSdemo

```sh
[bundle exec] fastlane ios iOSdemo
```

Build a new iOS demo on App Center with the current build number. You are responsible to tag the library and bump the version (and the build number).

### ios tvOSdemo

```sh
[bundle exec] fastlane ios tvOSdemo
```

Build a new tvOS demo on AppStore Connect and wait build processing. You are responsible to tag the library and bump the version (and the build number) after.

### ios tvOSdemoDSYMs

```sh
[bundle exec] fastlane ios tvOSdemoDSYMs
```

Send latest tvOS demo dSYMs to App Center, with optional 'version' or 'min_version' parameters.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
