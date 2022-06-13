//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

@import SRGDataProviderModel;

NS_ASSUME_NONNULL_BEGIN

@class SRGContinuousPlaybackViewController;

/**
 *  Continuous playback view controller delegate protocol.
 */
@protocol SRGContinuousPlaybackViewControllerDelegate <NSObject>

/**
 *  This method is called when the user proactively plays the upcoming media suggested during continuous playback.
 */
- (void)continuousPlaybackViewController:(SRGContinuousPlaybackViewController *)continuousPlaybackViewController didEngageInContinuousPlaybackWithUpcomingMedia:(SRGMedia *)upcomingMedia;

/**
 *  This method is called when the user cancels continuous playback of the suggested upcoming media.
 */
- (void)continuousPlaybackViewController:(SRGContinuousPlaybackViewController *)continuousPlaybackViewController didCancelContinuousPlaybackWithUpcomingMedia:(SRGMedia *)upcomingMedia;

/**
 *  This method is called when the users chooses to restart playback of the current media.
 */
- (void)continuousPlaybackViewController:(SRGContinuousPlaybackViewController *)continuousPlaybackViewController didRestartPlaybackWithMedia:(SRGMedia *)media cancelledUpcomingMedia:(SRGMedia *)upcomingMedia;

@end

/**
 *  View controller displayed during a continuous playback transition between two medias.
 */
API_AVAILABLE(tvos(9.0)) API_UNAVAILABLE(ios)
@interface SRGContinuousPlaybackViewController : UIViewController

/**
 *  Instantiate with current and upcoming media information. The view displays a countdown ending at the specified date.
 */
- (instancetype)initWithMedia:(SRGMedia *)media upcomingMedia:(SRGMedia *)upcomingMedia endDate:(NSDate *)endDate controller:(SRGLetterboxController *)controller;

/**
 *  The view controller delegate.
 */
@property (nonatomic, weak, nullable) id<SRGContinuousPlaybackViewControllerDelegate> delegate;

@end

@interface SRGContinuousPlaybackViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
