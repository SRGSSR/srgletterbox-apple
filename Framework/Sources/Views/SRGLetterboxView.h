//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@class SRGLetterboxView;

@protocol SRGLetterboxViewDelegate <NSObject>

@optional

/**
 *  This method gets called when the user interface enters or exit full screen.
 *
 *  @discussion A full-screen button is automatically displayed when (and only when) this method is implemented
 */
- (void)letterboxView:(SRGLetterboxView *)letterboxView didToggleFullScreen:(BOOL)isFullScreen animated:(BOOL)animated;

/**
 *  This method gets called when user interface controls are shown or hidden. You can call the `SRGLetterboxView`
 *  `-animateAlongsideUserInterfaceWithAnimations:completion` method from within this method implementation to
 *  perform animations alongside the built-in control animations
 */
- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView;

@end

IB_DESIGNABLE
@interface SRGLetterboxView : UIView <SRGAirplayViewDelegate, UIGestureRecognizerDelegate>

/**
 *  View optional delegate
 */
@property (nonatomic, weak, nullable) IBOutlet id<SRGLetterboxViewDelegate> delegate;

/**
 *  Return YES iff the the user interface (with the controls on it) is hidden
 *
 *  @discussion The view is initially created with a visible user interface. Call `-setUserInterfaceHidden:togglable:`
 *              to change this behavior
 */
@property (nonatomic, readonly, getter=isUserInterfaceHidden) BOOL userInterfaceHidden;

/**
 *  Return YES iff the user interface can be toggled by the user (i.e. hidden or shown by interacting with it)
 *
 *  @discussion The view is initially created with togglable state. Call `-setUserInterfaceHidden:togglable:`
 *              to change this behavior
 */
@property (nonatomic, readonly, getter=isUserInterfaceTogglable) BOOL userInterfaceTogglable;

/**
 *  Change the user interface controls behavior
 *
 *  @param hidden Whether the user interface must be hidden
 *  @param animated Whether the transition must be animated
 *  @param togglable Whether the interface can be shown or hidden by the user
 */
- (void)setUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated togglable:(BOOL)togglable;

/**
 *  Call this method from within the delegate `-letterboxViewWillAnimateUserInterface:` method implementation to provide
 *  the animations to be performed alongside the player user interface animations when controls are shown or hidden,
 *  or an optional block to be called on completion
 *
 *  @param animations The animations to be performed when controls are shown or hidden
 *  @param completion The block to be called on completion
 *
 *  @discussion Attempting to call this method outside the correct delegate method will throw an exception
 */
- (void)animateAlongsideUserInterfaceWithAnimations:(nullable void (^)(BOOL hidden))animations completion:(nullable void (^)(BOOL finished))completion;

/**
 *  Full screen state.
 */
@property (nonatomic, readonly, getter=isFullScreen) BOOL fullScreen;

/**
 *  Change the full screen state.
 *
 *  Calling this setter method will call the delegate method `-letterboxView:didToggleFullScreen:animated:`
 *
 *  @param fullscreen YES for full screen
 *  @param animated Whether the transition must be animated
 *
 *  @discussion If the delegate method `-letterboxView:didToggleFullScreen:animated:` is not implemented, no full screen 
 *              button is displayed, and this method doesn't do anything
 */
- (void)setFullScreen:(BOOL)fullScreen animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
