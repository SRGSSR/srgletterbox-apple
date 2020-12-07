# Getting started

The SRG Letterbox library provides three families of components:

* A controller to play medias, `SRGLetterboxController`. The controller automatically retrieves metadata associated with the playback (media information, as well as channel information for DVR and livestreams). It also manages errors and restarts playback after a network loss.
* Visual components reflecting what an associated controller is currently playing, and providing controls to manage playback:
   * On iOS, `SRGLetterboxView` is a `UIView` subclass which must be inserted into your application view hierarchy and bound to a controller, which can be changed at any time.
   * On tvOS, `SRGLetterboxViewController` is a `UIViewController` subclass you simply present to display content played by a controller. This controller can be provided at creation time or can be entirely managed by the view controller itself.
* On iOS, a service singletion, `SRGLetterboxService`, to enable application-wide features like AirPlay, picture in picture or control center integration.

The following guide describes how these components can be easily combined to add advanced media playback capabilities to your iOS or tvOS application.

## Audio session management

No audio session specific management is provided by the library. Managing audio sessions is entirely the responsibility of the application, which gives you complete freedom over how playback happens, especially in the background or when switching between applications.

For more information, please refer to the [official documentation](https://developer.apple.com/library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html). Audio sessions are a somewhat tricky topic, you should therefore read the documentation well, experiment, and test the behavior of your application on a real device.

In particular, you should ask yourself:

* What should happen when I was playing music with another app and my app is launched? Should the music continue? Maybe resume after my app stops playing?
* Do I want to be able to control AirPlay playback from the lock screen or the control center?
* Do I want videos to be _listened to_ when the device is locked, maybe also when the application is in the background?

Moreover, you should check that your application behaves well when receiving phone calls (in particular, audio playback should stop).

### Simple audio session setup

For most applications, offering a standard media playback experience for both audios and videos can be achieved by setuping the audio session as follows, usually in the application delegate:

```objective-c
[AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:NULL];
```

The playback category should be used for applications offering media playback, and is required for picture in picture support. 

## Playing medias with Letterbox controller

To play a media, instantiate and retain a Letterbox controller somewhere:

```objective-c
self.controller = [[SRGLetterboxController alloc] init];
```

then call one of the play methods on it, passing it a valid media URN (unique identifier of the media):

```objective-c
[self.controller playURN:@"urn:swi:video:42844052" atPosition:nil withPreferredSettings:nil];
```

You can also instantiate controllers directly in your xibs or storyboards if you prefer.

Playback methods optionally support a settings parameter, with which you can control how medias are played, for example the stream type, its quality, or whether the media must be played in the context of its full-length or rather as a standalone media.

A Letterbox controller can play any media URN from any SRG SSR business unit. You can also play an `SRGMedia` if you have one already, for example if you retrieved some media list from the `SRGDataProvider` library:

```objective-c
[self.controller playMedia:media atPosition:nil withPreferredSettings:nil];
```

The controller immediately starts playing the media in the background. If you want to display its contents and manage its playback, you must bind a Letterbox view to your controller (see below).

To stop playback for a controller, simply call the `-reset` method on it.

### Metadata and errors

Letterbox controller broadcasts metadata updates and errors through `SRGLetterboxMetadataDidChangeNotification` and `SRGLetterboxPlaybackDidFailNotification` notifications, respectively. You can use the information provided with these notifications to display playback-related information, like the title or description of what is currently be played. Letterbox controller also provides properties to access the current metadata at any time.

In most cases, applications should not need to perform additional requests for playback metadata: All standard information should readily be available from the controller itself.

## Letterbox view (iOS)

On iOS, to display what is currently being played by a controller, add an `SRGLetterboxView` instance somewhere in your application, either in code or using Interface Builder, and bind its `controller` property to a Letterbox controller. Nothing else is required, as this view automatically keeps in sync with the underlying controller. If you play another media or change the controller of a view, the view will automatically update to reflect the new content.

### Controls and overlays

The standard player controls (play / pause button, seek bar, etc.) and the chapter and segment timeline of a Letterbox view cannot be customised. You can still add your own controls on top of the player view and have them shown or hidden alongside the player controls, though. 

You can also respond to recommended intrinsic view size changes in the same way, e.g. when a timeline or a notification are displayed, or to better support arbitrary aspect ratios. Simply set a delegate for the player view and respond to user interface state changes, as follows:

```objective-c
- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView
{
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden, BOOL minimal, CGFloat aspectRatio, CGFloat heightOffset) {
        // Show or hide your own overlays here, or adjust your layout to respond to height changes
    } completion:nil];
}
```

Within the block, you can apply any `UIView` or layout change, as you would in a usual view animation block. All changes will be animated within the same transaction as the view animations. If layout constraints must be animated, you will need to add calls to `-layoutIfNeeded` to ensure correct behavior. For example, if the delegate is a view controller, a typical implementation would look like:

```objective-c
- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView
{
    [self.view layoutIfNeeded];
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden, BOOL minimal, CGFloat aspectRatio, CGFloat heightOffset) {
        // Show or hide your own overlays here, or adjust your layout to respond to height changes
        [self.view layoutIfNeeded];
    } completion:nil];
}
```

The `-animateAlongsideUserInterfaceWithAnimations:completion:` animation block provides information about whether the usual controls are visible (`hidden` property) or whether the interface is in a minimal state, usually because no media is available or an error has been encountered (`minimal` property). You should use this information to set the visibility of your own custom controls appropriately. 

It also provides information about the view intrinsic size (`aspectRatio` and `heightOffset`), which you can use to assign the view just the size it requires, so that its content does not have to expand or shrink. Refer to the modal view controller demo implementation for a concrete example. 

### Full screen

The `SRGLetterboxView` view presents a full screen button on its overlay interface, allowing to toggle between normal and full screen displays. This button is shown if and only if the `-letterboxView:toggleFullScreen:animated:withCompletionHandler:` delegate method is implemented. Since a Letterbox views can be added anywhere to the view hierarchy, you are responsible of managing the full screen layout, as well as the transition animation between the normal and full screen states.

Refer to the modal view controller demo implementation for a concrete example.

### Simultaneous playback

Your application can use as many controllers as needed. Each controller can at most be bound to one view, and you are free to change controller - view relationships at will depending on your needs.

When several controllers are playing at the same time, you might want to mute some of them, which can be achieved by setting the `muted` property to `NO`.

## Application-wide services (iOS)

The `SRGLetterboxService` singleton makes it possible to enable AirPlay and picture in picture for at most one Letterbox controller at a time. This automatically adds the following features for this controller:

 * AirPlay support.
 * Picture in picture (for devices supporting it).
 * Control center and lock screen media information.
 * Remote playback controls.
 
To enable application-wide services for a Letterbox controller, simply call:

```objective-c
[SRGLetterboxService.sharedService enableWithController:controller pictureInPictureDelegate:nil];
```

If a Letterbox view is bound to the controller, its user interface automatically reflects which services are available for the underlying controller, letting you toggle AirPlay or picture in picture directly from it.

#### Remark

In the example above, no picture in picture delegate is provided. All services except picture in picture will therefore be available (picture in picture delegates are discussed below).

### Target configuration

To be able to call the _enable_ method above, you must set the _Audio, AirPlay, and Picture in Picture_ flag of your target Background modes to ensure AirPlay, background audio and picture and picture work as intended. If this flag is not set, Letterbox will throw an exception when the above method is called.

### Disabling services

To disable services for the currently registered controller, call:

```objective-c
[SRGLetterboxService.sharedService disable];
```

This will disable all application-wide features, removing the media from the control center and lock screen as well. Any playback currently made via AirPlay and picture in picture will automatically be cancelled.

At any time, you can call the _enable_ method again with a new controller to enable application-wide services for it. This will automatically disable these services for any controllers which might already benefit from them, and enable them for the new one.

### Picture in picture

Picture in picture only makes sense when a controller has been bound to a Letterbox view. To respond to picture and picture events, most notably for dismissing and restoring your user interface, you must implement the mandatory `SRGLetterboxPictureInPictureDelegate` delegate methods. If no delegate is available, picture in picture will not be available, and the corresponding button will not be displayed on the Letterbox view.

Usually, a Letterbox view is part of a view controller view hiearchy. In such cases, providing the view controller itself as picture in picture delegate is a good idea. The picture in picture delegate is namely retained while picture in picture is in use, providing you with an easy way to restore the user interface as it was before picture in picture started.

Refer to the modal view controller demo for a concrete example.

#### Remark

Picture in picture requires your application to declare the corresponding background mode capability, as well as an audio session category set to `AVAudioSessionCategoryPlayback`.

## Letterbox view controller (tvOS)

On tvOS, to display what is currently played by a controller, instantiate an `SRGLetterboxViewController` instance and simply present it modally. You can optionally provide a Letterbox controller at creation time, or let the view controller instantiate one for you.

`SRGLetterboxViewController` provides the usual tvOS playback experience and displays segments in the top info panel. It also supports picture in picture natively.

### Analytics

Applications presenting `SRGLetterboxViewController` are responsible of calling one of the tracking methods available from `SRGAnalyticsTracker (PageViewTracking)` to ensure a corresponding page view is recorded.

Streaming analytics are automatically handled by the underlying `SRGLetterboxController` and do not require additional setup.

#### Remark

Picture in picture requires your application to declare the corresponding background mode capability, as well as an audio session category set to `AVAudioSessionCategoryPlayback`.

## Playlists and continuous playback

The Letterbox controller supports playlists as well as automatic playback of the next available media (continuous playback). To use these features, simply provide an object serving playlists conforming to the `SRGLetterboxControllerPlaylistDataSource` protocol, and assign it to the `playlistDataSource` controller property.

Once a playlist data source has been setup, you can skip to the next or previous item at any time using the dedicated methods available from the Letterbox controller `Playlists` category.

If you want playback to automatically continue with the next media in a playlist once playback of the current media ends, implement the optional `-continuousPlaybackTransitionDurationForController:` delegate method, defining the delay before playback of the next media begins. During the transition between two medias, an attached Letterbox view will display an overlay allowing the user to either directly play the next item or cancel the transition. 

If needed, the controller `ContinousPlayback` category provides complete information about continuous playback transition (start and end date, and media which will be played next).

You can be notified about the user engaging or cancelling continuous playback by implementing the dedicated methods from `SRGLetterboxViewDelegate` on iOS, or from `SRGLetterboxViewControllerDelegate` on tvOS. On tvOS playback of the current content restarts when continuous playback is cancelled. You can for example decide to stop the player and dismiss the view controller by implementing the cancellation delegate method accordingly:

```objective-c
- (void)letterboxViewController:(SRGLetterboxViewController *)letterboxViewController didCancelContinuousPlaybackWithUpcomingMedia:(SRGMedia *)upcomingMedia
{
    [letterboxViewController.controller reset];
    [self dismissViewControllerAnimated:YES completion:nil];
}
```

## Subtitles and audio tracks

Letterbox provides native support for alternative subtitles and audio tracks. Subtitle choice made by the user (either through the dedicated iOS button or the tvOS info panel) is persisted at the system level, and will be reapplied in subsequent playback contexts, e.g. when playing another media with `SRGMediaPlayerController` or `AVPlayerViewController` (or Safari on iOS). Conversely, choices made in other playback contexts will also determine the initial default audio and subtitle selection for playback with Letterbox. Please refer to the [official MediaAccessibility framework documentation](https://developer.apple.com/documentation/mediaaccessibility) for more information.

You can programmatically control subtitles and audio tracks by setting `audioConfigurationBlock` and `subtitleConfigurationBlock` blocks on the controller. These blocks are automatically called when playback starts to set the initial audio track and subtitle selection. Here is for example how you would apply German audio and French subtitles if available:

```objective-c
self.controller.audioConfigurationBlock = ^AVMediaSelectionOption * _Nonnull(NSArray<AVMediaSelectionOption *> * _Nonnull audioOptions, AVMediaSelectionOption * _Nonnull defaultAudioOption) {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(AVMediaSelectionOption * _Nullable option, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [[option.locale objectForKey:NSLocaleLanguageCode] isEqualToString:@"de"];
    }];
    return [audioOptions filteredArrayUsingPredicate:predicate].firstObject ?: defaultAudioOption;
};
self.controller.subtitleConfigurationBlock = ^AVMediaSelectionOption * _Nullable(NSArray<AVMediaSelectionOption *> * _Nonnull subtitleOptions, AVMediaSelectionOption * _Nullable audioOption, AVMediaSelectionOption * _Nullable defaultSubtitleOption) {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(AVMediaSelectionOption * _Nullable option, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [[option.locale objectForKey:NSLocaleLanguageCode] isEqualToString:@"fr"];
    }];
    return [subtitleOptions filteredArrayUsingPredicate:predicate].firstObject ?: defaultSubtitleOption;
};
``` 

If for some reason the audio and / or subtitle choice must be updated during playback, call `-[SRGLetterboxController reloadMediaConfiguration]` so that these blocks get called again.

You can also customize subtitle styling as well if needed:

```objective-c
AVTextStyleRule *rule = [[AVTextStyleRule alloc] initWithTextMarkupAttributes:@{ (id)kCMTextMarkupAttribute_ForegroundColorARGB : @[ @1, @1, @0, @0 ],
                                                                                 (id)kCMTextMarkupAttribute_ItalicStyle : @(YES)}];
self.controller.textStyleRules = @[rule];
``` 

## URL overrides and local file playback

You can play any stream URL in place of the one associated with a media composition information. This mechanism is most notably useful if you have downloaded a media and want to play the local file instead of the original stream.

To override the URL to be played for some URN, set the `contentURLOverridingBlock` of the controller playing the media. Please refer to the associated documentation for more information.

Note that Letterbox does not include any download manager. Your application is solely responsible of retrieving and storing the file.

## Long-form playback

Starting with iOS 13, Apple introduced the concept of long-form playback. Primarily intended for video content, preparing for long-form playback when displaying a player offers the system the ability to suggest available AirPlay devices. Even though the kind of content played with Letterbox cannot be known a priori (audio is not considered to be long-form), your application can still benefit from AirPlay suggestions.

AirPlay suggestions are entirely the responsibility of the application. To enable the corresponding behavior, add the `AVInitialRouteSharingPolicy` to your application `Info.plist`, with `LongFormVideo` as value, and call the appropriate preparation method where opening your Letterbox-based player view:

```objective-c
[AVAudioSession.sharedInstance prepareRouteSelectionForPlaybackWithCompletionHandler:^(BOOL shouldStartPlayback, AVAudioSessionRouteSelection routeSelection) {
    // Open the player
}];
```

For more information about long-form playback, have a look at the [dedicated WWDC session](https://developer.apple.com/videos/play/wwdc2019/501).

## Image copyrights

Media sometimes provide image copyright information via the `imageCopyright` property. If your application displays a Letterbox view, you should ensure that this information is somehow displayed in its vicinity.

## Statistics

Letterbox automatically sends media consumption measurements, provided an SRG Analytics tracker has been started. Refer to the [SRG Analytics](https://github.com/SRGSSR/srganalytics-apple) for information about how a tracker is started.

If needed, you can disable automatic tracking for a Letterbox controller by setting its `tracked` property to `NO`.

## Thread-safety

The library is intended to be used from the main thread only. Trying to use if from background threads results in undefined behavior.

## App Transport Security (ATS)

In the future, Apple will favor HTTPS over HTTP, and require applications to explicitly declare potentially insecure connections. These guidelines are referred to as [App Transport Security (ATS)](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW33).

For information about how you should configure your application to access our services, please refer to the dedicated [wiki topic](https://github.com/SRGSSR/srgdataprovider-apple/wiki/App-Transport-Security-(ATS)).
