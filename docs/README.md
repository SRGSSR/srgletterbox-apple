<p align="center"><img src="README-images/logo.png"/></p>

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## About

The SRG Letterbox library defines the official SRG SSR media player experience, packed into a single library providing:

* A controller to play audios and videos, which supports on-demand, live and DVR streams.
* A service to manage application-wide playback (iOS).
* A responsive player view with the official SRG SSR look and feel (iOS).
* A standard `AVPlayerViewController`-based player for straightforward integration (tvOS).
* Support for 360° videos (iOS).
* Support for chapter and segment browsing and selection. 
* Playlist support.
* Access to all SRG SSR business unit medias.
* Native AirPlay and picture in picture support (iOS)
* Seamless integration with the [SRG SSR analytics SDK](https://github.com/SRGSSR/srganalytics-ios) when used.
* ... and [a lot more](FEATURES.md).

<p align="center"><img src="README-images/letterbox.jpg"/></p>

To ensure a coherent visual player identity throughout SRG SSR applications, **the design is intentionally not intended for customization**, and will follow future design evolutions. If you need a completely custom player, you should rather use the [SRG Media Player library](https://github.com/SRGSSR/SRGMediaPlayer-iOS) instead, on top of which Letterbox itself is implemented.

## Compatibility

The library is suitable for applications running on iOS 9, tvOS 9 and above. The project is meant to be opened with the latest Xcode version.

## Contributing

If you want to contribute to the project, have a look at our [contributing guide](CONTRIBUTING.md).

## Installation

The library can be added to a project using Carthage. For more information about Carthage and its use, refer to its [official documentation](https://github.com/Carthage/Carthage).

### Installation with content protection

The ability to play protected content (e.g. livestreams, foreign TV series) is provided by an internal [SRG Content Protection](https://github.com/SRGSSR/srgcontentprotection-ios) framework. If you have access to it, integrate Letterbox by adding the following dependencies to your `Cartfile`: 

```
github "SRGSSR/srgletterbox-ios"
github "SRGSSR/srgcontentprotection-ios"
```

Check the [wiki](https://github.com/SRGSSR/srgletterbox-ios/wiki/Version-matrix) for the recommended version of SRG Content Protection to use.

### Installation without content protection

If you have no access to the internal [SRG Content Protection](https://github.com/SRGSSR/srgcontentprotection-ios) framework, integrate Letterbox by adding the following dependencies to your `Cartfile`: 

```
github "SRGSSR/srgletterbox-ios"
github "SRGSSR/srgcontentprotection-fake-ios"
```

Check the [wiki](https://github.com/SRGSSR/srgletterbox-ios/wiki/Version-matrix) for the recommended version of SRG Content Protection to use.

With this setup, non-protected content only (e.g. in-house productions or audio content) will be playable.

### Dependencies

The library requires the following frameworks to be added to any target requiring it:

* `ComScore`: The comScore framework.
* `FXReachability`: A reachability framework.
* `libextobjc`: A utility framework.
* `MAKVONotificationCenter`: A safe KVO framework.
* `Mantle`:  The framework used to parse the data.
* `SRGAnalytics`: The main analytics framework.
* `SRGAnalytics_MediaPlayer`: The media player analytics companion framework.
* `SRGAnalytics_DataProvider`: The data provider analytics companion framework.
* `SRGAppearance`: The appearance framework.
* `SRGContentProtection`: The framework to enable playback of protected medias.
* `SRGDiagnostics`: Framework for collecting diagnostic information.
* `SRGLetterbox`: The Letterbox library framework.
* `SRGLogger`: The framework used for internal logging.
* `SRGMediaPlayer`: The media player framework (if not already in your project).
* `SRGNetwork`: A networking framework.
* `TCCore`: The core TagCommander framework.
* `TCSDK`: The main TagCommander SDK framework.
* `YYWebImage`: A framework for image retrieval.

### Dynamic framework integration

1. Run `carthage update` to update the dependencies (which is equivalent to `carthage update --configuration Release`). 
2. Add the frameworks listed above and generated in the `Carthage/Build/(iOS|tvOS)` folder to your target _Embedded binaries_.

If your target is building an application, a few more steps are required:

1. Add a _Run script_ build phase to your target, with `/usr/local/bin/carthage copy-frameworks` as command.
2. Add each of the required frameworks above as input file `$(SRCROOT)/Carthage/Build/(iOS|tvOS)/FrameworkName.framework`.

### Static framework integration

1. Run `carthage update --configuration Release-static` to update the dependencies. 
2. Add the frameworks listed above and generated in the `Carthage/Build/(iOS|tvOS)/Static` folder to the _Linked frameworks and libraries_ list of your target.
3. Also add any resource bundle `.bundle` found within the `.framework` folders to your target directly.
4. Some non-statically built framework dependencies are built in the `Carthage/Build/(iOS|tvOS)` folder. Add them by following the _Dynamic framework integration_ instructions above.
5. Add the `-all_load` flag to your target _Other linker flags_.

## Building the project

A [Makefile](../Makefile) provides several targets to build and package the library. The available targets can be listed by running the following command from the project root folder:

```
make help
```

Alternatively, you can of course open the project with Xcode and use the available schemes.

Private project settings (keys, tokens, etc.) are stored [in a private repository](https://github.com/SRGSSR/srgletterbox-ios-configuration), pulled under the `Configuration` directory when running `make setup` (or any other target depending on it). The SHA-1 of the configuration commit which is used is explicitly provided in the `Makefile`. Settings are therefore versioned alongside the project, providing for reproducible builds.

If you need to make changes to the settings:

1. Perform the required changes in the `Configuration` directory (and in the project as well if needed).
1. Switch to the `Configuration` directory and commit changes there.
1. Update the [Makefile](../Makefile) `CONFIGURATION_COMMIT_SHA1` variable to point at the configuration commit to use.
1. Push all commits when you are ready.

## Usage

When you want to use classes or functions provided by the library in your code, you must import it from your source files first.

### Usage from Objective-C source files

Import the global header file using:

```objective-c
#import <SRGLetterbox/SRGLetterbox.h>
```

or directly import the module itself:

```objective-c
@import SRGLetterbox;
```

### Usage from Swift source files

Import the module where needed:

```swift
import SRGLetterbox
```

### Working with the library

To learn about how the library can be used, have a look at the [getting started guide](GETTING_STARTED.md).

### Logging

The library internally uses the [SRG Logger](https://github.com/SRGSSR/srglogger-ios) library for logging, within the `ch.srgssr.letterbox` subsystem. This logger either automatically integrates with your own logger, or can be easily integrated with it. Refer to the SRG Logger documentation for more information.

### Control preview in Interface Builder

Interface Builder can render custom controls dropped onto a storyboard or a xib. If you want to enable this feature for Letterbox controls, and after Carthage has been run, open the `Carthage/Checkouts/srgletterbox-ios/Designables` directory, **copy** the `SRGLetterboxDesignables.m` file it contains to your project and add it to your target.

When dropping a view (e.g. `SRGLetterboxView`) onto a storyboard or xib, Xcode will now build your project in the background and render the view when it is done.

If rendering does not work properly:

* Be sure that your project correctly compiles
* If you still get `dlopen` errors, this means some frameworks are not available to Xcode when it runs your project for rendering. This usually means that the `copy-frameworks` build phase described in the [Carthage readme](https://github.com/Carthage/Carthage#getting-started) has not been setup properly. Be sure that all SRG Media Player dependencies are properly copied (see above framework list).

## Demo project

To test what the library is capable of, run the associated demo.

#### URL schemes (iOS)

The iOS demo application can be opened with a custom URL scheme having the following format: `letterbox(-nightly|-debug)`.

* Open a media within the player: `[scheme]://open?media=[media_urn]`.
* A `&server=[server_name]` parameter can be added to force a server selection. The available server list can be found in the _Server_ section of the application settings.

## Known issues

Control center and lock screen integrations are not working reliably in the iOS simulator. This is a known simulator-only limitation, everything works fine on a device. 

Moreover, standard view controller transitions (e.g. screen edge pan in a navigation controller), more generally those based on `UIPercentDrivenInteractiveTransition`, will interfere with playback, since they alter layer speeds (and thus `AVPlayerLayer` speed). For a perfect result you should therefore implement your own transition animator. An example is supplied with the demo.

## Standard system behaviors

If playback is paused from the iOS application and the device is locked afterwards, the lock screen will surprisingly not display playback controls. This is standard behavior (Apple Podcasts application works the same). Playback can be restarted from the control center, though.

Moreover, video playback is paused by the system automatically when putting the application in the background, except when picture in picture is used.

## License

See the [LICENSE](../LICENSE) file for more information.
