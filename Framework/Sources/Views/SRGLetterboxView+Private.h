//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxView.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Interface for internal use.
 */
@interface SRGLetterboxView (Private)

/**
 *  The preferred segment timeline height.
 *
 *  Will be use when displaying the segment timeline. Negative value will be ignore and value set to 0.f;
 *
 *  @discussion By default, the height is 120.f. To always hide the segment timeline, call
 *  `-setPreferredTimelineHeight:animated:` with a 0.f value.
 */
@property (nonatomic, readonly) CGFloat preferredTimelineHeight;

/**
 *  Change the preferred segment timeline height
 *
 *  @param preferredTimelineHeight set the hight of the timeline
 *  @param animated Whether the transition must be animated.
 *
 *  @discussion By default, the height is 120.f. To always hide the segment timeline, set it to 0.f.
 */
- (void)setPreferredTimelineHeight:(CGFloat)preferredTimelineHeight animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
