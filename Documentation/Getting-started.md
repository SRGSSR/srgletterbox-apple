_Sinec major changes are expected, only basic integration guidelines are provided. Those should be enough to get you started, though_

Getting started
===============

The SRG Letterbox library is mostly made of two components:

* A low-level service to play medias
* A player view reflecting what the service is currently playing and to control its playback

The following describes how both are used to easily add media playback capabilities to your application.

## Project configuration

You must enable the _Audio, Airplay, and Picture in Picture_ flag of your target Background modes to ensure Airplay, background audio and picture and picture work as intended. If this flag is not enabled, Letterbox will throw an exception when used.

## Playing medias

To play a media, simply access the Letterbox service singleton, and call one of the play methods on it:

```objective-c
SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:swi:video:42844052"];
if (URN) {
	[[SRGLetterboxService sharedService] playURN:URN withPreferredQuality:SRGQualityNone];
}
```

The service can play any video from any SRG SSR business unit. If you already have the `SRGMedia` object to be played, you can directly call:

```objective-c
[[SRGLetterboxService sharedService] playMedia:media withPreferredQuality:SRGQualityNone];
```

The service immediately starts playing the media in the background. If you want to display its contents and manage its playback, you must add a player view somewhere in your application. This view works both for audios and videos.

To stop playback, simply call the `-reset` method on the service.

## Displaying the player view

Simply add a `SRGLetterboxView` instance somewhere in your application, either in code or using Interface Builder. Nothing else is required, as this view automatically displays what is currently being played by the service singleton.

## Metadata and errors

The service broadcasts metadata updates and errors through `SRGLetterboxServiceMetadataDidChangeNotification` and `SRGLetterboxServicePlaybackDidFailNotification` notifications, respectively. You can use the information provided with these notifications to enrich your the view around the player with playback information (e.g. title or description of what is currently be played).

## Controls and overlays

The standard player controls (play / pause button, seek bar, etc.) of Letterbox cannot be customised. You can still add your own controls on top of the player view and have them shown or hidden alongside the player controls, though. Simply set a delegate for the player view and respond to overlay changes, as follows:

```objective-c
- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView
{
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden) {
        // Show or hide your own overlays here
    } completion:nil];
}
```

Within the block, you can use any kind of `UIView` or layout animations, as you would in a usual view animation block.

## Picture in picture

To respond to picture and picture events, mostly for restoring your interface, you must implement the `SRGLetterboxServiceDelegate` delegate methods. Refer to the demo implementation for a concrete example.

## Airplay

Airplay works out of the box and does not require any code.

## Statistics

If your project has started an [SRG Analytics](https://github.com/SRGSSR/srganalytics-ios) tracker, stream playback statistics will automatically be sent.