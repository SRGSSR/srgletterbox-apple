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
- (void)letterboxView:(SRGLetterboxView *)letterboxView toggledFullScreen:(BOOL)isFullScreen;

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
 *  User interface controls state
 */
@property (nonatomic, getter=isUserInterfaceHidden, readonly) BOOL userInterfaceHidden;

/**
 *  User interface controls interaction state
 *
 *  YES, the user can tap on the screen to toggle controls (shown or hidden), with an inactivity timer to hide it.
 *  NO, the user can't tap on the screen to toggle controls (shown or hidden).
 *  By default: YES
 *
 *  @discussion Could be change with -setUserInterfaceHidden:animated:allowedToBeShownOrHidden: method
 */
@property (nonatomic, getter=isUserInterfaceAllowedToBeShownOrHidden, readonly) BOOL userInterfaceAllowedToBeShownOrHidden;

/**
 *  Change the user interface controls state.
 *
 *  @param hidden Shown or hidden the user interface controls
 *  @param animated Animate the shown or hidden transition
 *  @param allowedToBeShownOrHidden Allowed after to hide or show user interface with the inactivity timer or by taping on the frame
 */
- (void)setUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated allowedToBeShownOrHidden:(BOOL)allowedToBeShownOrHidden;

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

@property (nonatomic, readonly, getter=isFullScreen) BOOL fullScreen;

@end

NS_ASSUME_NONNULL_END
