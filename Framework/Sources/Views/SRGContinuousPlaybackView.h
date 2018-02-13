//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  View displayed during a continuous playback transition.
 */
IB_DESIGNABLE
@interface SRGContinuousPlaybackView : UIView

/**
 *  The controller which the view is associated with.
 */
@property (nonatomic, weak, nullable) SRGLetterboxController *controller;

@end

NS_ASSUME_NONNULL_END
