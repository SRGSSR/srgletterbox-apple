//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxControllerView.h"

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class SRGContinuousPlaybackView;

/**
 *  View delegate.
 */
@protocol SRGContinuousPlaybackViewDelegate <NSObject>

/**
 *  This method is called when the user proactively chooses to play the suggested media.
 */
- (void)continuousPlaybackView:(SRGContinuousPlaybackView *)continuousPlaybackView didEngageWithUpcomingMedia:(SRGMedia *)upcomingMedia;

/**
 *  This method is called when the user cancels continuous playback of the suggested media.
 */
- (void)continuousPlaybackView:(SRGContinuousPlaybackView *)continuousPlaybackView didCancelWithUpcomingMedia:(SRGMedia *)upcomingMedia;

@end

/**
 *  View displayed during a continuous playback transition.
 */
IB_DESIGNABLE
@interface SRGContinuousPlaybackView : SRGLetterboxControllerView

/**
 *  View delegate.
 */
@property (nonatomic, weak, nullable) IBOutlet id<SRGContinuousPlaybackViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
