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
 *  This method gets called when user toggles the full screen button.
 *  If you implement this delegate method, the full screen button will appear.
 *  Because SRGLetterboxView is
 */
- (void)letterboxView:(SRGLetterboxView *)letterboxView toggledFullScreen:(BOOL)isFullScreen animated:(BOOL)animated;

/**
 *  This method gets called when user interface controls are shown or hidden. You can call the `SRGLetterboxView`
 *  `-animateAlongsideUserInterfaceWithAnimations:completion` method from within this method implementation to
 *  perform animations alongside the built-in control animations
 */
- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView;

@end

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
 *  Call this setter method will call the delagate method `-letterboxView:toggledFullScreen:animated:`
 *
 *  @param fullscreen Enter or exit full screen
 *  @param animated Animate full screen transition
 *
 *  @discussion If you didn't implement the delegate method `-letterboxView:toggledFullScreen:`, no full screen button
 *  will appear, and this method won't have any effect.
 */
- (void)setFullScreen:(BOOL)fullScreen animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
