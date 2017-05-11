//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

#import <AVKit/AVKit.h>
#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Available Letterbox commands for playback control remotes, control center and lock screen.
 */
typedef NS_OPTIONS(NSInteger, SRGLetterboxCommands) {
    SRGLetterboxCommandMinimal              = 0,                // Minimal controls (play / pause only).
    SRGLetterboxCommandSkipBackward         = 1 << 0,           // -30 seconds.
    SRGLetterboxCommandSkipForward          = 1 << 1,           // +30 seconds.
    SRGLetterboxCommandSeekBackward         = 1 << 2,           // Seek backward.
    SRGLetterboxCommandSeekForward          = 1 << 3,           // Seek forward.
    SRGLetterboxCommandPreviousTrack        = 1 << 4,           // Previous track.
    SRGLetterboxCommandNextTrack            = 1 << 5            // Next track.
};

/**
 *  Delegate protocol for picture in picture implementation. User interface behavior when entering or exiting picture
 *  in picture is namely the responsibility of the application, and is formalized by the following protocol.
 */
@protocol SRGLetterboxPictureInPictureDelegate <NSObject>

/**
 *  Called when picture in picture is started, providing you a chance to dismiss the user interface from which picture 
 *  in picture was started.
 *
 *  Return `YES` if you dismissed or began dismissing the user interface from this method. When returning `YES`,
 *  restoration delegate methods will be called if needed when picture in picture ends (see below). In this case,
 *  the `-letterboxShouldRestoreUserInterfaceForPictureInPicture` method still lets you decide, at the moment
 *  restoration takes place, whether restoration must actually happen or not.
 *
 *  If your return `NO`, no restoration will take place when picture in picture is exited.
 */
- (BOOL)letterboxDismissUserInterfaceForPictureInPicture;

/**
 *  Called when picture in picture might need user interface restoration. Return `YES` if this is the case (most probably
 *  when the player view from which picture in picture was initiated is not visible anymore).
 */
- (BOOL)letterboxShouldRestoreUserInterfaceForPictureInPicture;

/**
 *  Called when a restoration process takes place.
 *
 *  @parameter completionHandler A completion block which MUST be called at the VERY END of the restoration process
 *                               (e.g. after at the end of a modal presentation animation). Failing to do so leads to
 *                               undefined behavior. The completion block must be called with `restored` set to `YES`
 *                               iff the restoration was successful.
 */
- (void)letterboxRestoreUserInterfaceForPictureInPictureWithCompletionHandler:(void (^)(BOOL restored))completionHandler;

@optional

/**
 *  Called when picture in picture has been started.
 */
- (void)letterboxDidStartPictureInPicture;

/**
 *  Called when picture in picture ended.
 */
- (void)letterboxDidEndPictureInPicture;

/**
 *  Called if playback was ended from picture in picture.
 *
 *  @discussion The `-letterboxDidEndPictureInPicture` method is called in this case as well.
 */
- (void)letterboxDidStopPlaybackFromPictureInPicture;

@end

/**
 *  Delegate protocol for playback command customization.
 *
 *  @discussion For commands occupying the same location in the control center and on the lock screen, iOS chooses which 
 *              button will be available. Other commands remain available when using a remote, though:
 *                - Tap twice to play the next track.
 *                - Tap three times to play the previous track.
 *                - Tap twice and hold to seek forward.
 *                - Tap three times and hold to see backward.
 */
@protocol SRGLetterboxCommandDelegate <NSObject>

/**
 *  Return the set of commands which should be available during playback. If not implemented, the seek and skip commands
 *  will be available.
 *
 *  @discussion The play / pause command cannot be customized. This method is called continuously during playback,
 *              you can therefore alter the availability of the commands during playback as well.
 */
- (SRGLetterboxCommands)letterboxAvailableCommands;

@optional

/**
 *  Called when the previous track must be played.
 */
- (void)letterboxWillSkipToPreviousTrack;

/**
 *  Called when the next track mjust be played.
 */
- (void)letterboxWillSkipToNextTrack;

@end

/**
 *  The Letterbox service is a singleton, which can provide the following application-wide features for one Letterbox 
 *  controller at a time:
 *    - AirPlay
 *    - Picture in picture (for devices supporting it)
 *    - Control center and lock screen media information
 *    - Remote playback controls
 *
 *  These features namely only make sense for one controller at a time, which explains why a Letterbox controller
 *  does not offert them by default. At any time, calling the `-enableWithController:pictureInPictureDelegate:`
 *  method enables service features for a specific controller. If services were already enabled for another controller,
 *  those will be transferred to the new controller.
 *
 *  If you want to disable background services, you can call `-disable` at any time. This will remove the ability to
 *  use AirPlay or picture in picture, and clear control center and lock screen information. Any AirPlay or picture
 *  in picture playback will be immediately stopped.
 */
@interface SRGLetterboxService : NSObject <AVPictureInPictureControllerDelegate>

/**
 *  The service singleton instance.
 */
+ (SRGLetterboxService *)sharedService;

/**
 *  Enable service application-wide features for the specified controller. All services are enabled, except picture
 *  in picture which requires a proper delegate to be defined (and, of course, a compatible device).
 *
 *  @param controller               The Letterbox controller to enable application-wide services for. The controller 
 *                                  is retained.
 *  @param pictureInPictureDelegate The picture in picture delegate. Unlike most delegates, this delegate is RETAINED.
 *                                  If none is provided, picture in picture will not be available for the controller.
 *                                  Note that you can provide a delegate in all cases, even if some devices you target 
 *                                  do not actually support picture in picture (the delegate won't be saved, though). 
 *                                  The delegate will be released when a new delegate is set, or when `-disable` is called.
 *
 *  @discussion The 'Audio, Airplay, and Picture in Picture' flag of your target background modes must be enabled, otherwise
 *              this method will throw an exception when called.
 *
 *              The picture in picture delegate is provided alongside the controller when calling this method, so that 
 *              the exact picture in picture starting context is set with the controller. Usually, since picture in picture 
 *              is started from a view controller, a good delegate candidate is the view controller itself, which knows how
 *              it can be dismissed and presented again. Since the delegate is retained, this also provides you with an
 *              easy way to restore the view controller in the exact same state as it was before picture in picture
 *              started.
 */
- (void)enableWithController:(SRGLetterboxController *)controller
    pictureInPictureDelegate:(nullable id<SRGLetterboxPictureInPictureDelegate>)pictureInPictureDelegate;

/**
 *  Disable services iff the controller is the one currently attached to the service. Does nothing otherwise.
 */
- (void)disableForController:(SRGLetterboxController *)controller;

/**
 *  Disable application-wide services (any playback using one of those services will be stopped).
 */
- (void)disable;

/**
 *  The controller for which application-wide services are enabled, if any.
 */
@property (nonatomic, readonly, nullable) SRGLetterboxController *controller;

/**
 *  The picture in picture delegate, if any has been set. Use it to enable and customize picture in picture behavior.
 *
 *  @discussion This property always returns `nil` on devices which do not support picture in picture.
 */
@property (nonatomic, readonly, nullable) id<SRGLetterboxPictureInPictureDelegate> pictureInPictureDelegate;

/**
 *  The playback command delegate, if any has been set. Use it to customize commands available in the control center
 *  and on the lock screen, as well as with remotes (e.g. headsets).
 */
@property (nonatomic, weak, nullable) id<SRGLetterboxCommandDelegate> commandDelegate;

/**
 *  If set to `YES`, playback never switches to full-screen playback on an external screen. This is especially handy 
 *  when you need to mirror your application for presentation purposes.
 *
 *  Default is `NO`.
 */
@property (nonatomic, getter=isMirroredOnExternalScreen) BOOL mirroredOnExternalScreen;

@end

@interface SRGLetterboxService (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
