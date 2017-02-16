
Getting started
===============

The SRG Letterbox library is made of three components:

* `SRGLetterboxController`: A controller to play medias.
* `SRGLetterboxView`: A player view reflecting what an associated controller is currently playing, and providing controls to manage playback.
* `SRGLetterboxService`: A service to enable application-wide features like Airplay and picture in picture.

The following guide describes how these components can be easily combined to add advanced media playback capabilities to your application.

## Playing medias with Letterbox controller

To play a media, instantiate and retain a Letterbox controller somewhere:

```objective-c
self.controller = [[SRGLetterboxController alloc] init];
```

and call one of the play methods on it:

```objective-c
SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:swi:video:42844052"];
if (URN) {
	[self.controller playURN:URN];
}
```

You can also instantiate controllers directly in your xibs or storyboards if you prefer.

A Letterbox controller can play any media from any SRG SSR business unit, simply starting from its URN. You can play an `SRGMedia` directly if you have one, for example if you already loaded some media list from the `SRGDataProvider` library:

```objective-c
[self.controller playMedia:media];
```

The controller immediately starts playing the media in the background. If you want to display its contents and manage its playback, you must bind a Letterbox view to your controller. 

To stop playback for a controller, simply call the `-reset` method on it.

### Metadata and errors

Each controller broadcasts metadata updates and errors through `SRGLetterboxMetadataDidChangeNotification` and `SRGLetterboxPlaybackDidFailNotification` notifications, respectively. You can use the information provided with these notifications to build a richer view around the player, e.g. by displaying more playback information (title or description of what is currently be played). For most use cases, your application should not need to perform additional requests in its player view: All standard information should readily be available from the controller itself (which provides properties to retrieve the currently available information).

### Simultaneous playback

Your application can use as many controllers as needed. Each controller can at most be bound to one view, and you are free to change controller - view relationships as will depending on your needs. When several controllers are playing at the same time, you might want to mute some of them, which can be achieved by setting the `muted` property to `NO`.

## Letterbox view

To display what is currently played by a controller, add a `SRGLetterboxView` instance somewhere in your application, either in code or using Interface Builder, and bind its `controller` property to a Letterbox controller. Nothing else is required, as this view automatically displays what is currently being played by the controller. If you play another media or change the controller of a view, the view will automatically update to reflect the new content being played.

### Controls and overlays

The standard player controls (play / pause button, seek bar, etc.) of a Letterbox view cannot be customised. You can still add your own controls on top of the player view and have them shown or hidden alongside the player controls, though. Simply set a delegate for the player view and respond to user interface state changes, as follows:

```objective-c
- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView
{
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden) {
        // Show or hide your own overlays here
    } completion:nil];
}
```

Within the block, you can apply any `UIView` or layout change, as you would in a usual view animation block. All changes will be animated within the same transaction as the controls animation.

Refer to the modal view controller demo implementation for a concrete example. 

### Full screen

The `SRGLetterboxView` view presents a full screen button on its overlay interface, allowing to toggle between normal and full screen displays. This button is shown if and only if the `-letterboxView:toggleFullScreen:animated:withCompletionHandler:` delegate method is implemented. Since a Letterbox views can be added anywhere to the view hierarchy, you are responsible of managing the full screen layout, as well as the transition animation between the normal and full screen states.

Refer to the modal view controller demo implementation for a concrete example. 

## Application-wide services

The `SRGLetterboxService` singleton makes it possible to enable Airplay and picture in picture for at most one Letterbox controller at a time. This automatically adds the following features for this controller:

 * Airplay support.
 * Picture in picture (for devices supporting it).
 * Control center and lock screen media information.
 * Remote playback controls.
 
To enable application-wide services for a Letterbox controller, simply call:

```objective-c
[[SRGLetterboxService sharedService] enableWithController:controller pictureInPictureDelegate:nil];
```

If a Letterbox view is bound to the controller, its user interface automatically reflects which services are available for the underlying controller, letting you toggle Airplay or picture in picture directly from it.

#### Remark

In this example, no picture in picture delegate is provided. All services except picture in picture will be available (picture in picture delegates are discussed below).

### Target configuration

To be able to call the _enable_ method above, you must set the _Audio, Airplay, and Picture in Picture_ flag of your target Background modes to ensure Airplay, background audio and picture and picture work as intended. If this flag is not set, Letterbox will throw an exception when the above method is called.

### Disabling services

To disable services for the currently registered controller, call:

```objective-c
[[SRGLetterboxService sharedService] disable];
```

This will disable all application-wide features, removing the media from the control center and lock screen as well. Any playback currently made via Airplay and picture in picture will automatically be cancelled.

At any time, you can call the _enable_ method again with a new controller to enable application-wide services for it. This will automatically disable these services for any controllers which might already benefit from them.

### Picture in picture

Picture in picture only makes sense when a controller has been bound to a Letterbox view. To respond to picture and picture events, most notably for dismissing and restoring your user interface, you must implement the mandatory `SRGLetterboxPictureInPictureDelegate` delegate methods. If no delegate has been set, picture in picture will not be available, and the corresponding button will not be displayed on the Letterbox view.

Usually, a Letterbox view is part of a view controller view hiearchy. In such cases, providing the view controller itself as picture in picture delegate is a good idea. Unlike usual delegates, the picture in picture delegate is namely retained, providing you with a good way to restore the user interface as it was before picture in picture started.

Refer to the modal view controller demo for a concrete example.

## Statistics

If your project has started an [SRG Analytics](https://github.com/SRGSSR/srganalytics-ios) tracker, stream playback statistics will automatically be sent when a controller plays a media. This behavior can be disabled by setting the `tracked` property of a controller to `NO`.