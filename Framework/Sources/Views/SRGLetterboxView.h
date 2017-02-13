//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

#import <UIKit/UIKit.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@class SRGLetterboxView;

/**
 *  Letterbox view delegate protocol for optiona full-screen support and additional overlay animations.
 */
@protocol SRGLetterboxViewDelegate <NSObject>

@optional

/**
 *  This method gets called when the user interface is about to enter or exit full screen. The completion handler must
 *  be called from within the method implementation when the transition is complete, otherwise the behavior is undefined.
 *
 *  @discussion A full-screen toggle button is automatically displayed when (and only when) this method is implemented.
 */
- (void)letterboxView:(SRGLetterboxView *)letterboxView toggleFullScreen:(BOOL)fullScreen animated:(BOOL)animated withCompletionHandler:(void (^)(BOOL finished))completionHandler;

/**
 *  This method gets called when user interface controls are shown or hidden. You can call the `SRGLetterboxView`
 *  `-animateAlongsideUserInterfaceWithAnimations:completion` method from within this method implementation to
 *  perform animations alongside the built-in control animations.
 */
- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView;

@end

/**
 *  The Letterbox view provides a way to display and manage what is currently being played by a Letterbox controller
 *  (@see `SRGLetterboxController`). The view is provided with minimalist non-customizable overlay controls, but offers
 *  a way to integrate additional elements as if they were part of the overlay.
 *
 *  A view can be bound to at most one controller at a time, and displays what is currently being played by the controller. 
 *  It is immediately updated when the content played by the controller changes, or when the controller itself is changed.
 *
 *  To instantiate a Letterbox view, simply drop an instance onto a xib or a storyboard, set constraints appropriately, 
 *  and bind it to a controller. If the controller itself has been added as an object to the storyboard, this setup can 
 *  entirely be done in Interface builder. Then start playing a media with the controller.
 *
 *  ## Controls
 *
 *  The following controls are supported out of the box for any kind of media played in a Letterbox controller (on-demand,
 *  live and DVR audio and video streams):
 *    - Buttons to control playback (play / pause, +/- 30 seconds, back to live for DVR streams)
 *    - Slider with elapsed and remaining time (on-demand streams), or time position (DVR streams)
 *    - Error display
 *    - Airplay, picture in picture and subtitles / audio tracks buttons
 *    - Optional full screen button (see below)
 *    - Overlay displayed when external Airplay playback is active
 *    - Activity indicator
 *    - Image placeholder when loading or playing on an external display
 *
 *  The controls are displayed initially, and hidden after an inactivity delay. The user is also able to toggle the
 *  controls on or off by tapping on the overlay. If needed, you can programmatically show or hide the controls, or 
 *  disable the ability for the user to toggle them, by calling `-setUserInterfaceHidden:animated:togglable:.
 *
 *  Controls are shown and hidden with a fade in / fade out animation. You can animate additional view overlays alongside
 *  them by setting a view delegate and implementing the corresponding delegate protocol method.
 *  
 *  ## Full-screen
 *
 *  Full-screen is a usual feature of media players. Since the view and view controller hierarchy is not known to the
 *  Letterbox view, full-screen is optional and can be implemented in your application by setting a view delegate and
 *  implementing the corresponding delegate protocol method. A full-screen button is then automatically added to the 
 *  player overlay controls, and your animations will be triggered when the player is toggled between normal and 
 *  full-screen displays.
 *
 *  ## Picture in picture
 *
 *  A picture in picture button is displayed on compatible devices if application-wide services have been enabled for
 *  the controller bound to the view (@see `SRGLetterboxService`). If picture in picture is enabled for the controller
 *  when the associated view gets displayed, picture in picture is automatically stopped. If full-screen has been
 *  implemented and your Letterbox view occupies the whole screen when full screen, pressing the home button will
 *  automatically switch playback to picture in picture. This behavior is an Apple standard and cannot be disabled.
 *
 *  ## Airplay
 *
 *  An Airplay button is displayed if application-wide services have been enabled for the controller bound to the
 *  view (@see `SRGLetterboxService`) and an external display is available. During Airplay playback, controls cannot
 *  be toggled on or off (they can be hidden programmatically, though).
 
 *  If `mirroredOnExternalScreen` has been set to `YES` on the service singleton, the Letterbox view will behave as 
 *  if no Airplay playback was possible, and won't switch to external display. This way, your application can be mirrored 
 *  as is via Airplay, which is especially convenient for presentation purposes.
 */
IB_DESIGNABLE
@interface SRGLetterboxView : UIView <SRGAirplayViewDelegate, UIGestureRecognizerDelegate>

/**
 *  The controller bound to the view. Can be changed at any time.
 */
@property (nonatomic, weak, nullable) IBOutlet SRGLetterboxController *controller;

/**
 *  View optional delegate.
 */
@property (nonatomic, weak, nullable) IBOutlet id<SRGLetterboxViewDelegate> delegate;

/**
 *  Return `YES` iff the the user interface (with the controls on it) is hidden.
 *
 *  @discussion The view is initially created with a visible user interface. Call `-setUserInterfaceHidden:animated:togglable:`
 *              to change this behavior.
 */
@property (nonatomic, readonly, getter=isUserInterfaceHidden) BOOL userInterfaceHidden;

/**
 *  Return `YES` iff the user interface can be toggled by the user (i.e. hidden or shown by interacting with it).
 *
 *  @discussion The view is initially created with togglable state. Call `-setUserInterfaceHidden:animated:togglable:`
 *              to change this behavior.
 */
@property (nonatomic, readonly, getter=isUserInterfaceTogglable) BOOL userInterfaceTogglable;

/**
 *  Change the user interface controls behavior.
 *
 *  @param hidden Whether the user interface must be hidden.
 *  @param animated Whether the transition must be animated.
 *  @param togglable Whether the interface can be shown or hidden by the user.
 *
 *  @discussion During Airplay playback:
 *                - If togglable was set to `YES`, the user interface will be always displayed
 *                - If togglable was set to `NO`, the user interface will stay as it was before
 *              Calling this method during Airplay playback to show or hide controls only works if togglabe is set to
 *              `YES`. Moreover, the interface cannot be shown when an error has been encountered.
 */
- (void)setUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated togglable:(BOOL)togglable;

/**
 *  Call this method from within the delegate `-letterboxViewWillAnimateUserInterface:` method implementation to provide
 *  the animations to be performed alongside the player user interface animations when controls are shown or hidden,
 *  and an optional block to be called on completion.
 *
 *  @param animations The animations to be performed when controls are shown or hidden.
 *  @param completion The block to be called on completion.
 *
 *  @discussion Attempting to call this method outside the correct delegate method will throw an exception.
 */
- (void)animateAlongsideUserInterfaceWithAnimations:(nullable void (^)(BOOL hidden))animations completion:(nullable void (^)(BOOL finished))completion;

/**
 *  Return `YES` when the view is full screen.
 *
 *  @discussion This value will be updated once the completion handler in `-letterboxView:toggleFullScreen:animated:withCompletionHandler:`
 *              has been called.
 */
@property (nonatomic, readonly, getter=isFullScreen) BOOL fullScreen;

/**
 *  Enable or disable full screen.
 *
 *  Calling this method will call the delegate method `-letterboxView:toggleFullScreen:animated:withCompletionHandler:`.
 *
 *  @param fullScreen `YES` for full screen.
 *  @param animated Whether the transition must be animated or not.
 *
 *  @discussion If the delegate method `-letterboxView:toggleFullScreen:animated:withCompletionHandler:` is not implemented, no full screen
 *              button is displayed, and this method doesn't do anything. Calling this method when a transition is running does nothing.
 */
- (void)setFullScreen:(BOOL)fullScreen animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
