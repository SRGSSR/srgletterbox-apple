//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class SRGContinuousPlaybackView;

@protocol SRGContinuousPlaybackViewDelegate <NSObject>

/**
 *  This method is called when the user selected the play button.
 */
- (void)continuousPlaybackView:(SRGContinuousPlaybackView *)continuousPlaybackView didSelectUpcomingMedia:(SRGMedia *)media;

/**
 *  This method is called when the user canceled the Continuous playback transition.
 */
- (void)continuousPlaybackView:(SRGContinuousPlaybackView *)continuousPlaybackView didCancelUpcomingMedia:(SRGMedia *)media;

@end

/**
 *  View displayed during a continuous playback transition.
 */
IB_DESIGNABLE
@interface SRGContinuousPlaybackView : UIView

/**
 *  The controller which the view is associated with.
 */
@property (nonatomic, weak, nullable) SRGLetterboxController *controller;

/**
 *  View optional delegate.
 */
@property (nonatomic, weak, nullable) IBOutlet id<SRGContinuousPlaybackViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
