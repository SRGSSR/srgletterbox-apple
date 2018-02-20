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
 *  This method is called when the user ends of the Continuous playback transition.
 *
 *  @param selected  `YES` if the user clicked on the play button, otherwise, `NO`.
 */
- (void)continuousPlaybackView:(SRGContinuousPlaybackView *)continuousPlaybackView didEndContinuousPlaybackTransitionWithMedia:(SRGMedia *)media selected:(BOOL)selected;

/**
 *  This method is called when the user cancels the Continuous playback transition.
 */
- (void)continuousPlaybackView:(SRGContinuousPlaybackView *)continuousPlaybackView didCancelContinuousPlaybackTransitionWithMedia:(SRGMedia *)media;

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
