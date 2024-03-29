//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

NS_ASSUME_NONNULL_BEGIN

@class SRGLetterboxViewController;

/**
 *  Letterbox view controller delegate.
 */
API_AVAILABLE(tvos(9.0)) API_UNAVAILABLE(ios)
@protocol SRGLetterboxViewControllerDelegate <NSObject>

@optional

/**
 *  This method is called when the user proactively plays the media suggested during continuous playback.
 */
- (void)letterboxViewController:(SRGLetterboxViewController *)letterboxViewController didEngageInContinuousPlaybackWithUpcomingMedia:(SRGMedia *)upcomingMedia;

/**
 *  This method is called when the user cancels continuous playback of the suggested media.
 */
- (void)letterboxViewController:(SRGLetterboxViewController *)letterboxViewController didCancelContinuousPlaybackWithUpcomingMedia:(SRGMedia *)upcomingMedia;

/**
 *  This method is called when the user changed the playback speed.
 */
- (void)letterboxViewController:(SRGLetterboxViewController *)letterboxViewController didSelectPlaybackRate:(float)playbackRate;

/**
 *  This method is called when picture is picture will start.
 */
- (void)letterboxViewControllerWillStartPictureInPicture:(SRGLetterboxViewController *)letterboxViewController API_AVAILABLE(tvos(14.0));

/**
 *  This method is called when picture is picture did start.
 */
- (void)letterboxViewControllerDidStartPictureInPicture:(SRGLetterboxViewController *)letterboxViewController API_AVAILABLE(tvos(14.0));

/**
 *  This method is called when picture is picture will stop.
 */
- (void)letterboxViewControllerWillStopPictureInPicture:(SRGLetterboxViewController *)letterboxViewController API_AVAILABLE(tvos(14.0));

/**
 *  This method is called when picture is picture did stop.
 */
- (void)letterboxViewControllerDidStopPictureInPicture:(SRGLetterboxViewController *)letterboxViewController API_AVAILABLE(tvos(14.0));

@end

/**
 *  Letterbox view controller is a full-fledged tvOS Letterbox-based playback experience. It provides tight integration
 *  with the system standard player and its features (metadata and segment support, interstitials for blocked content,
 *  thumbnails, continuous playback, etc.). Unlike Letterbox iOS support, where your application is supposed to display
 *  a Letterbox view, on tvOS you should simply present a Letterbox view controller to play some content.
 *
 *  This view controller is intended to be presented modally. Attempting to presesnt it in any other way results in
 *  undefined behavior.
 */
API_AVAILABLE(tvos(9.0)) API_UNAVAILABLE(ios)
@interface SRGLetterboxViewController : UIViewController

/**
 *  Instantiate a view controller whose playback is managed by the specified controller. If none is provided a default
 *  one will be automatically created.
 */
- (instancetype)initWithController:(nullable SRGLetterboxController *)controller;

/**
 *  The controller used for playback.
 */
@property (nonatomic, readonly) SRGLetterboxController *controller;

/**
 *  The view controller delegate.
 */
@property (nonatomic, weak, nullable) id<SRGLetterboxViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
