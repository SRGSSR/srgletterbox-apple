fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
## iOS
### ios tests
```
fastlane ios tests
```
Run library tests
### ios iOSnightly
```
fastlane ios iOSnightly
```
Build a new iOS nightly demo on App Center
### ios tvOSnightly
```
fastlane ios tvOSnightly
```
Build a new tvOS nightly demo on AppStore Connect and wait build processing.
### ios tvOSnightlyDSYMs
```
fastlane ios tvOSnightlyDSYMs
```
Send latest tvOS nightly dSYMs to App Center, with optional 'version' or 'min_version' parameters.
### ios iOSdemo
```
fastlane ios iOSdemo
```
Build a new iOS demo on App Center with the current build number. You are responsible to tag the library and bump the version (and the build number).
### ios tvOSdemo
```
fastlane ios tvOSdemo
```
Build a new tvOS demo on AppStore Connect and wait build processing. You are responsible to tag the library and bump the version (and the build number) after.
### ios tvOSdemoDSYMs
```
fastlane ios tvOSdemoDSYMs
```
Send latest tvOS demo dSYMs to App Center, with optional 'version' or 'min_version' parameters.

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
