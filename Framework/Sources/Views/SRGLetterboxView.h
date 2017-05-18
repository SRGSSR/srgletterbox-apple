//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

#import <UIKit/UIKit.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class SRGLetterboxView;

/**
 *  Letterbox view delegate protocol for optional full-screen support and view animations.
 */
@protocol SRGLetterboxViewDelegate <NSObject>

@optional

/**
 *  This method gets called when the user interface is about to enter or exit full screen. The completion handler must
 *  be called from within the method implementation when the transition is complete, otherwise the behavior is undefined.
 *
 *  @discussion A full-screen toggle button is automatically displayed when (and only when) this method is implemented.
 *              The optional `-letterboxViewShouldDisplayFullScreenToggleButton:` method provides a way to override this
 *              behavior.
 */
- (void)letterboxView:(SRGLetterboxView *)letterboxView toggleFullScreen:(BOOL)fullScreen animated:(BOOL)animated withCompletionHandler:(void (^)(BOOL finished))completionHandler;

/**
 *  This method is called when the user interface is considering displaying a full-screen button. Implement this method 
 *  and return `YES` to display the button.
 *
 *  If not implemented, the behavior is equivalent to returning `YES`.
 *
 *  @discussion This method is only called if `-letterboxView:toggleFullScreen:animated:withCompletionHandler:` has been
 *              implemented. It will also be called when full-screen state the view layout changes, so that the user 
 *              interface can be appropriately updated if needed (e.g. to hide the full-screen button for some orientation).
 */
- (BOOL)letterboxViewShouldDisplayFullScreenToggleButton:(SRGLetterboxView *)letterboxView;

/**
 *  This method gets called when user interface controls or segments are shown or hidden. You can call the `SRGLetterboxView`
 *  `-animateAlongsideUserInterfaceWithAnimations:completion` method from within this method implementation to perform 
 *  animations alongside the built-in control animations.
 */
- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView;

/**
 *  This method is called when the Letterbox view slider did scroll. The segment corresponding to the current slider
 *  position is provided, if any. The `interactive` boolean is `YES` if scrolling was interactively made by the user.
 */
- (void)letterboxView:(SRGLetterboxView *)letterboxView didScrollWithSegment:(nullable SRGSegment *)segment interactive:(BOOL)interactive;

/**
 *  This method is called when the user has actively selected a segment.
 */
- (void)letterboxView:(SRGLetterboxView *)letterboxView didSelectSegment:(SRGSegment *)segment;

/**
 *  This method is called when the user did a long press on a segment cell.
 */
- (void)letterboxView:(SRGLetterboxView *)letterboxView didLongPressSegment:(SRGSegment *)segment;

/**
 *  Called when the user interface needs to determine whether a favorite icon must be displayed. If no delegate has been
 *  set or if this method is not implemented, no favorite icon will be displayed.
 *
 *  The method is called when appropriate, but you can manually trigger a favorite status refresh by calling the
 *  LetterboxView `-setNeedsSegmentFavoritesUpdate` method.
 */
- (BOOL)letterboxView:(SRGLetterboxView *)letterboxView shouldDisplayFavoriteForSegment:(SRGSegment *)segment;

@end

/**
 *  A Letterbox view provides a way to display and manage what is currently being played by a Letterbox controller
 *  (@see `SRGLetterboxController`). The view is provided with minimalist non-customizable overlay controls, but offers
 *  a way to integrate additional elements as if they were part of the overlay.
 *
 *  A view can be bound to at most one controller at a time, and displays what is currently being played by the controller. 
 *  It is immediately updated when the content played by the controller changes, or when the controller itself is changed.
 *
 *  Note that you can bind a controller to several Letterbox views, but only the last one to be bound will display the
 *  video content of what is being played. Other Letterbox views will only provide a way to control playback. This is
 *  a known an assumed limitation, as having several views display the same media at the same time makes little sense.
 *
 *  To instantiate a Letterbox view, simply drop an instance onto a xib or a storyboard, set constraints appropriately, 
 *  and bind it to a controller. If the controller itself has been added as an object to the storyboard, this setup can 
 *  entirely be done in Interface builder. Then start playing a media with the controller.
 *
 *  ## Controls and views
 *
 *  The following controls and views are supported out of the box, most of them available for any kind of media played 
 *  by a Letterbox controller (on-demand, live and DVR audio and video streams):
 *    - Buttons to control playback (play / pause, +/- 30 seconds, back to live for DVR streams)
 *    - Slider with elapsed and remaining time (on-demand streams), or time position (DVR streams)
 *    - Error display
 *    - Airplay, picture in picture and subtitles / audio tracks buttons
 *    - Optional full screen button (see below)
 *    - Overlay displayed when external Airplay playback is active
 *    - Activity indicator
 *    - Image placeholder when loading or playing on an external display
 *
 *  Controls are displayed initially, and hidden after an inactivity delay. The user is also able to toggle the
 *  controls on or off by tapping on the overlay. If needed, you can programmatically show or hide the controls, or 
 *  disable the ability for the user to toggle them, by calling `-setUserInterfaceHidden:animated:togglable:.
 *
 *  Controls are shown and hidden with a fade in / fade out animation. You can animate additional view overlays alongside
 *  them by setting a view delegate and implementing the corresponding delegate protocol method.
 *
 *  ## Segments
 *
 *  The view automatically loads and displays segments below the player. Since the segment timeline takes some space
 *  when present, you can have your code respond to timeline height adjustments by setting a Letterbox view delegate
 *  and implementing the `-letterboxViewWillAnimateUserInterface:` method to update your layout accordingly. You can
 *  also respond to the `-letterboxView:didScrollWithSegment:interactive:` delegate method to respond to the timeline
 *  being moved, either interactively or during normal playback
 *  
 *  ## Long press on segments and favorites
 *
 *  Basic non-customizable support for favorites is provided. A long-press `-letterboxView:didLongPressSegment:` 
 *  delegate method is called when the user holds her finger still on a cell for a few seconds, providing you with 
 *  the ability to store a segment as being favorited. The `-letterboxView:shouldDisplayFavoriteForSegment:` delegate
 *  method lets you decide whether a segment cell should display a favorite icon or not.
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
 *  ## AirPlay
 *
 *  An AirPlay button is displayed if application-wide services have been enabled for the controller bound to the
 *  view (@see `SRGLetterboxService`) and an external display is available. During AirPlay playback, controls cannot
 *  be toggled on or off (they will keep the current visibility at the time Airplay has been enabled).
 
 *  If `mirroredOnExternalScreen` has been set to `YES` on the service singleton, the Letterbox view will behave as 
 *  if no AirPlay playback was possible, and won't switch to external display. This way, your application can be 
 *  mirrored as is via AirPlay, which is especially convenient for presentation purposes.
 */
IB_DESIGNABLE
@interface SRGLetterboxView : UIView <SRGAirplayViewDelegate, SRGTimeSliderDelegate, UIGestureRecognizerDelegate>

/**
 *  The controller bound to the view. The controller can be changed at any time, the view will automatically be updated
 *  accordingly.
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
 *  Change the user interface controls visibility. Togglability is not altered.
 *
 *  @param hidden   Whether the user interface must be hidden.
 *  @param animated Whether the transition must be animated.
 *
 *  @discussion When AirPlay is enabled or an error has been encountered, the UI behavior is overridden. This method
 *              will only apply changes once overrides are lifted.
 */
- (void)setUserInterfaceHidden:(BOOL)userInterfaceHidden animated:(BOOL)animated;

/**
 *  Change the user interface controls behavior.
 *
 *  @param hidden    Whether the user interface must be hidden.
 *  @param animated  Whether the transition must be animated.
 *  @param togglable Whether the interface can be shown or hidden by the user.
 *
 *  @discussion When AirPlay is enabled or an error has been encountered, the UI behavior is overridden. This method
 *              will only apply changes once overrides are lifted.
 */
- (void)setUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated togglable:(BOOL)togglable;

/**
 *  Call this method from within the delegate `-letterboxViewWillAnimateUserInterface:` method implementation to provide
 *  the animations to be performed alongside the player user interface animations when controls, segments or notifications
 *  are shown or hidden. An optional block to be called on completion can be provided as well.
 *
 *  @param animations The animations to be performed when these subviews are shown or hidden. The main view is usually 
 *                    animated in response to more information being displayed within it (e.g. a segment timeline or a
 *                    notification). If the view frame is not changed, the player will be temporarily shrinked to make room
 *                    for such additional elements. If you prefer your parent layout to provide more space so that
 *                    shrinking does not occur, the required height offset is provided as information, so that you can
 *                    adjust your layout accordingly. You can e.g. use this value as the constant of an aspect ratio layout 
 *                    constraint to make the player view slightly taller.
 *  @param completion The block to be called on completion.
 *
 *  @discussion Attempting to call this method outside the correct delegate method is a programming error and will throw
 *              an exception.
 */
- (void)animateAlongsideUserInterfaceWithAnimations:(nullable void (^)(BOOL hidden, CGFloat heightOffset))animations completion:(nullable void (^)(BOOL finished))completion;

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
 *  @param animated   Whether the transition must be animated or not.
 *
 *  @discussion If the delegate method `-letterboxView:toggleFullScreen:animated:withCompletionHandler:` is not implemented, no full screen
 *              button is displayed, and this method doesn't do anything. Calling this method when a transition is running does nothing.
 */
- (void)setFullScreen:(BOOL)fullScreen animated:(BOOL)animated;

/**
 *  Return `YES` iff timeline was forced to be always hidden.
 */
@property (nonatomic, readonly, getter=isTimelineAlwaysHidden) BOOL timelineAlwaysHidden;

/**
 *  Set to `YES` to force the timeline to be always hidden. The default value is `NO`.
 *
 *  @param timelineAlwaysHidden `YES` to hide the timeline.
 *  @param animated             Whether the change must be animated or not.
 *
 *  @discussion When changing this value, the current control visibility state is not altered. If controls were already hidden,
 *              the timeline behavior change will not be observed until controls are displayed again.
 */
- (void)setTimelineAlwaysHidden:(BOOL)timelineAlwaysHidden animated:(BOOL)animated;

/**
 *  Call to schedule an update request for segment favorites.
 *
 *  For more information, @see `SRGLetterboxViewDelegate`.
 */
- (void)setNeedsSegmentFavoritesUpdate;

@end

NS_ASSUME_NONNULL_END
