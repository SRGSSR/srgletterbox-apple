//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGMediaPlayer;

NS_ASSUME_NONNULL_BEGIN

// Forward declarations.
@protocol SRGLetterboxTimeSliderThumbnailDelegate;

/**
 *  Custom slider displaying a small time bubble attached to its knob.
 */
API_UNAVAILABLE(tvos)
@interface SRGLetterboxTimeSlider : SRGTimeSlider

/**
 *  The time slider delegate.
 */
@property (nonatomic, weak, nullable) id<SRGLetterboxTimeSliderThumbnailDelegate> thumbnailDelegate;

@end

/**
 *  Time slider thumbnail delegate protocol.
 */
API_UNAVAILABLE(tvos)
@protocol SRGLetterboxTimeSliderThumbnailDelegate <NSObject>

/**
 *  @param time The time.
 *
 *  @return Thumbnail image matching the specified time, if any.
 */
- (nullable UIImage *)srg_timeSliderThumbnailAtTime:(CMTime)time;

@end

NS_ASSUME_NONNULL_END
