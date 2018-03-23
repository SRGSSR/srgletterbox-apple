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
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios test
```
fastlane ios test
```
Run library tests
### ios nightly
```
fastlane ios nightly
```
Build a new nightly demo on HockeyApp
### ios demo
```
fastlane ios demo
```
Build a new demo on HockeyApp with the current build number. If we're not in a release process (master or release/*), it bumps the build number. You are responsible to tag the library version.

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
