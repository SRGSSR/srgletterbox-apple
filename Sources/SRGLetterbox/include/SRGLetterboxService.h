//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

@import AVKit;
@import SRGDataProvider;
@import SRGMediaPlayer;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Available Letterbox commands for playback control remotes, control center and lock screen.
 *
 *  @discussion Skip commands (if available) take precedence over previous / next track commands.
 */
typedef NS_OPTIONS(NSInteger, SRGLetterboxCommands) {
    SRGLetterboxCommandMinimal                      = 0,                // Minimal controls (play / pause only).
    SRGLetterboxCommandSkipBackward                 = 1 << 0,           // -10 seconds.
    SRGLetterboxCommandSkipForward                  = 1 << 1,           // +30 seconds.
    SRGLetterboxCommandPreviousTrack                = 1 << 2,           // Previous track.
    SRGLetterboxCommandNextTrack                    = 1 << 3,           // Next track.
    SRGLetterboxCommandChangePlaybackPosition       = 1 << 4,           // Slider to seek within the media.
    SRGLetterboxCommandLanguageSelection            = 1 << 5,           // Language selection (audio track and subtitles; AirPlay only).
    SRGLetterboxCommandChangePlaybackRate           = 1 << 6            // Playback rate cycle selection between supported playback rates (CarPlay only).
} API_UNAVAILABLE(tvos);

/**
 *  Default command set.
 */
static SRGLetterboxCommands SRGLetterboxCommandsDefault API_UNAVAILABLE(tvos) = SRGLetterboxCommandSkipForward | SRGLetterboxCommandSkipBackward
    | SRGLetterboxCommandChangePlaybackPosition | SRGLetterboxCommandLanguageSelection | SRGLetterboxCommandChangePlaybackRate;

/**
 *  Delegate protocol for picture in picture implementation. User interface behavior when entering or exiting picture
 *  in picture is namely the responsibility of the application, and is formalized by the following protocol.
 */
API_UNAVAILABLE(tvos)
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
 *  @param completionHandler A completion block which MUST be called at the VERY END of the restoration process
 *                           (e.g. after at the end of a modal presentation animation). Failing to do so leads to
 *                           undefined behavior. The completion block must be called with `restored` set to `YES`
 *                           iff the restoration was successful.
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
 *  The Letterbox service is a singleton, which can provide the following application-wide features for one Letterbox 
 *  controller at a time:
 *    - AirPlay.
 *    - Picture in picture (for devices supporting it).
 *    - Control center and lock screen media information.
 *    - Remote playback controls.
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
API_UNAVAILABLE(tvos)
@interface SRGLetterboxService : NSObject

/**
 *  The service singleton instance.
 */
@property (class, nonatomic, readonly) SRGLetterboxService *sharedService;

/**
 *  Enable service application-wide features for the specified controller. All services are enabled, except picture
 *  in picture which requires a proper delegate to be defined (and, of course, a compatible device).
 *
 *  @param controller               The Letterbox controller to enable application-wide services for. The controller 
 *                                  is retained.
 *  @param pictureInPictureDelegate The picture in picture delegate. The delegate is weakly referenced, but automatically
 *                                  retained while picture in picture is in use. A delegate must be available for picture
 *                                  in picture to be available. Note that you can provide a delegate even if some devices
 *                                  you target do not actually support picture in picture (the delegate will be ignored,
 *                                  though). A registered delegate will be released when a new delegate is set, or when
 *                                  `-disable` is called.
 *
 *  @discussion The 'Audio, AirPlay, and Picture in Picture' flag of your target background modes must be enabled, otherwise
 *              this method will throw an exception when called.
 *
 *              The picture in picture delegate is provided alongside the controller when calling this method, so that 
 *              the exact picture in picture starting context is set with the controller. Usually, since picture in picture 
 *              is started from a view controller, a good delegate candidate is the view controller itself, which knows how
 *              it can be dismissed and presented again. Since the delegate is retained during picture in picture use, this
 *              also provides you with an easy way to restore the view controller in the exact same state as it was before
 *              picture in picture started. If you decide for another delegate, be sure that your application keeps the
 *              delegate alive (except if you don't need it anymore and picture in picture is active, in which case you
 *              can safely release it and let the service keep it alive until picture in picture is stopped).
 *
 *  Warning: If you plan to implement restoration from picture in picture, you must avoid usual built-in iOS modal
 *           presentations, as they are implemented using `UIPercentDrivenInteractiveTransition`. You must use a
 *           custom modal transition instead and avoid implementing it using `UIPercentDrivenInteractiveTransition`.
 *           The reason is that `UIPercentDrivenInteractiveTransition` varies the time offset of a layer and thus
 *           messes up with the player local time. This makes picture in picture restoration unreliable (sometimes it
 *           works, sometimes it does not and the animation is ugly).
 *
 *           Picture in picture also temporarily disables external playback for the associated player. You should not
 *           attempt to change this property while picture in playback is running, otherwise the behavior is undefined.
 *           When picture in picture playback starts or stops, the configuration block (if any) is called so that the
 *           player configuration can be properly setup and restored.
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
 *  The picture in picture delegate, if any is available.
 *
 *  @discussion This property always returns `nil` on devices which do not support picture in picture.
 */
@property (nonatomic, readonly, weak) id<SRGLetterboxPictureInPictureDelegate> pictureInPictureDelegate;

/**
 *  If set to `YES`, playback never switches to full-screen playback on an external screen. This is especially handy 
 *  when you need to mirror your application for presentation purposes.
 *
 *  Default is `NO`.
 */
@property (nonatomic, getter=isMirroredOnExternalScreen) BOOL mirroredOnExternalScreen;

@end

/**
 *  Now playing information and command customization. Commands are available both from the control center as well
 *  as on remotes (e.g. headset remote or Apple Watch).
 *
 *  Fow now playing information and commands to work, the audio session category must be set to `AVAudioSessionCategoryPlayback`.
 *
 *  @discussion For commands occupying the same location in the control center and on the lock screen, iOS chooses which
 *              button will be available. Other commands remain available when using a remote, though. A headset button,
 *              for example, allows you to:
 *                - Tap twice to play the next track.
 *                - Tap three times to play the previous track.
 *                - Tap twice and hold to seek forward.
 *                - Tap three times and hold to seek backward.
 */
@interface SRGLetterboxService (NowPlayingInfoAndCommands)

/**
 *  Iff set to `YES`, the control center and lock screen automatically display media information and associated
 *  playback commands. Applications can set this value to `NO` if they want to disable this integration, allowing
 *  them to precisely control which information is displayed.
 *
 *  Default is `YES`.
 */
@property (nonatomic, getter=areNowPlayingInfoAndCommandsEnabled) BOOL nowPlayingInfoAndCommandsEnabled;

/**
 *  Return the set of commands which might be available during playback. Whether or not a command is available or not
 *  ultimately depends on the media being played and the current playback position.
 *
 *  The default value is `SRGLetterboxCommandsDefault`.
 */
@property (nonatomic) SRGLetterboxCommands allowedCommands;

@end

@interface SRGLetterboxService (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
