# Getting started

The SRG Letterbox library is made of three core components:

* `SRGLetterboxController`: A controller to play medias. The controller automatically retrieves metadata associated with the playback (media information, as well as channel information for DVR and livestreams). It also manages errors and restarts playback after a network loss.
* `SRGLetterboxView`: A player view reflecting what an associated controller is currently playing, and providing controls to manage playback. The controller of a Letterbox view can be changed at any time.
* `SRGLetterboxService`: A service to enable application-wide features like AirPlay, picture in picture or control center integration.

The following guide describes how these components can be easily combined to add advanced media playback capabilities to your application.

## Playing medias with Letterbox controller

To play a media, instantiate and retain a Letterbox controller somewhere:

```objective-c
self.controller = [[SRGLetterboxController alloc] init];
```

then call one of the play methods on it, passing it a valid media URN (unique identifier of the media):

```objective-c
[self.controller playURN:@"urn:swi:video:42844052" standalone:NO];
```

You can also instantiate controllers directly in your xibs or storyboards if you prefer.

Playback methods expect a `standalone` parameter, with which you can control how medias are played. If set to `NO`, the media is played in its context (e.g. the full episode if the media is one of its sequences). If set to `YES`, playback is restricted to the media only and no context is provided.

A Letterbox controller can play any media URN from any SRG SSR business unit. You can also play an `SRGMedia` if you have one already, for example if you retrieved some media list from the `SRGDataProvider` library:

```objective-c
[self.controller playMedia:media standalone:NO];
```

The controller immediately starts playing the media in the background. If you want to display its contents and manage its playback, you must bind a Letterbox view to your controller (see below).

To stop playback for a controller, simply call the `-reset` method on it.

### Metadata and errors

Letterbox controller broadcasts metadata updates and errors through `SRGLetterboxMetadataDidChangeNotification` and `SRGLetterboxPlaybackDidFailNotification` notifications, respectively. You can use the information provided with these notifications to display playback-related information, like the title or description of what is currently be played. Letterbox controller also provides properties to access the current metadata at any time.

In most cases, applications should not need to perform additional requests for playback metadata: All standard information should readily be available from the controller itself.

### Simultaneous playback

Your application can use as many controllers as needed. Each controller can at most be bound to one view, and you are free to change controller - view relationships at will depending on your needs.

 When several controllers are playing at the same time, you might want to mute some of them, which can be achieved by setting the `muted` property to `NO`.

## Letterbox view

To display what is currently played by a controller, add a `SRGLetterboxView` instance somewhere in your application, either in code or using Interface Builder, and bind its `controller` property to a Letterbox controller. Nothing else is required, as this view automatically displays what is currently being played by the controller. If you play another media or change the controller of a view, the view will automatically update to reflect the new content being played.

### Controls and overlays

The standard player controls (play / pause button, seek bar, etc.) and the chapter and segment timeline of a Letterbox view cannot be customised. You can still add your own controls on top of the player view and have them shown or hidden alongside the player controls, though. 

You can also respond to view height changes in the same way, e.g. when a timeline or a notification are displayed. Simply set a delegate for the player view and respond to user interface state changes, as follows:

```objective-c
- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView
{
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden, BOOL minimal, CGFloat heightOffset) {
        // Show or hide your own overlays here, or adjust your layout to respond to height changes
    } completion:nil];
}
```

Within the block, you can apply any `UIView` or layout change, as you would in a usual view animation block. All changes will be animated within the same transaction as the controls animation. If layout constraints must be animated, you will need to add calls to `-layoutIfNeeded` to ensure correct behavior. For example, if the delegate is a view controller, a typical implementation would look like:

```objective-c
- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView
{
    [self.view layoutIfNeeded];
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden, BOOL minimal, CGFloat heightOffset) {
        // Show or hide your own overlays here, or adjust your layout to respond to height changes
        [self.view layoutIfNeeded];
    } completion:nil];
}
```

The `-animateAlongsideUserInterfaceWithAnimations:completion:` animation block provides information about whether the usual controls are visible (`hidden` property) or whether the interface is in a minimal state, usually because no media is available or an error has been encountered (`minimal` property). You should use this information to set the visibility of your own custom controls appropriately. Refer to the modal view controller demo implementation for a concrete example. 

### Full screen

The `SRGLetterboxView` view presents a full screen button on its overlay interface, allowing to toggle between normal and full screen displays. This button is shown if and only if the `-letterboxView:toggleFullScreen:animated:withCompletionHandler:` delegate method is implemented. Since a Letterbox views can be added anywhere to the view hierarchy, you are responsible of managing the full screen layout, as well as the transition animation between the normal and full screen states.

Refer to the modal view controller demo implementation for a concrete example. 

## Application-wide services

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

Picture in picture only makes sense when a controller has been bound to a Letterbox view. To respond to picture and picture events, most notably for dismissing and restoring your user interface, you must implement the mandatory `SRGLetterboxPictureInPictureDelegate` delegate methods. If no delegate has been set, picture in picture will not be available, and the corresponding button will not be displayed on the Letterbox view.

Usually, a Letterbox view is part of a view controller view hiearchy. In such cases, providing the view controller itself as picture in picture delegate is a good idea. Unlike usual delegates, the picture in picture delegate is namely retained, providing you with a good way to restore the user interface as it was before picture in picture started.

Refer to the modal view controller demo for a concrete example.

## Playlists and continuous playback

The Letterbox controller supports playlists as well as automatic playback of the next available media (continuous playback). To use these features, simply provide an object serving playlists conforming to the `SRGLetterboxControllerPlaylistDataSource` protocol, and assigned to the `playlistDataSource` controller property.

Once a playlist data source has been setup, you can skip to the next or previous item at any time using the dedicated methods available from the Letterbox controller `Playlists` category.

If you want playback to automatically continue with the next media in a playlist once playback of the current media ends, implement the optional `-continuousPlaybackTransitionDurationForController:` delegate method, defining the delay before playback of the next media begins. During the transition between two medias, an attached Letterbox view will display an overlay allowing the user to either directly play the next item or cancel the transition. 

If needed, the controller `ContinousPlayback` category provides complete information about continuous playback transition (start and end date, and media which will be played next).

## URL overrides and local file playback

You can play any stream URL in place of the one associated with a media composition information. This mechanism is most notably useful if you have downloaded a media and want to play the local file instead of the original stream.

To override the URL to be played for some URN, set the `contentURLOverridingBlock` of the controller playing the media. Please refer to the associated documentation for more information.

Note that Letterbox does not include any download manager. Your application is solely responsible of retrieving and storing the file.

## Image copyrights

Media sometimes provide image copyright information via the `imageCopyright` property. If your application displays a Letterbox view, you should ensure that this information is somehow displayed in its vicinity.

## Statistics

Letterbox automatically sends media consumption measurements, provided an SRG Analytics tracker has been started. Refer to the [SRG Analytics](https://github.com/SRGSSR/srganalytics-ios) for information about how a tracker is started.

If needed, you can disable automatic tracking for a Letterbox controller by setting its `tracked` property to `NO`.

## Thread-safety

The library is intended to be used from the main thread only. Trying to use if from background threads results in undefined behavior.

## App Transport Security (ATS)

In a near future, Apple will favor HTTPS over HTTP, and require applications to explicitly declare potentially insecure connections. These guidelines are referred to as [App Transport Security (ATS)](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW33).

For information about how you should configure your application to access our services, please refer to the dedicated [wiki topic](https://github.com/SRGSSR/srgdataprovider-ios/wiki/App-Transport-Security-(ATS)).
