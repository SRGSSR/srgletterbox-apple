//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxControllerView.h"

@import SRGMediaPlayer;

NS_ASSUME_NONNULL_BEGIN

// Forward declarations.
@protocol SRGLetterboxTimeSliderDelegate;

/**
 *  Custom slider displaying a small time bubble attached to its knob.
 */
API_UNAVAILABLE(tvos)
@interface SRGLetterboxTimeSlider : SRGLetterboxControllerView <SRGTimeSliderDelegate>

/**
 *  The time slider delegate.
 */
@property (nonatomic, weak, nullable) id<SRGLetterboxTimeSliderDelegate> delegate;

/**
 *  The time corresponding to the current slider position.
 *
 *  @discussion While dragging, this property may not reflect the value current time property of the asset being played.
 *              The slider `time` property namely reflects the current slider knob position, not the actual player
 *              position.
 */
@property (nonatomic, readonly) CMTime time;

/**
 *  For DVR and live streams, returns the date corresponding to the current slider position. If the date cannot be
 *  determined or for on-demand streams, the method returns `nil`.
 */
@property (nonatomic, readonly, nullable) NSDate *date;

/**
 *  Return `YES` iff the current slider position matches the conditions of a live feed.
 *
 *  @discussion While dragging, this property may not reflect the value returned by the media player controller `live`
 *              property. The slider `live` property namely reflects the current slider knob position, not the actual
 *              player position.
 */
@property (nonatomic, readonly, getter=isLive) BOOL live;

@end

/**
 *  Time slider thumbnail delegate protocol.
 */
API_UNAVAILABLE(tvos)
@protocol SRGLetterboxTimeSliderDelegate <NSObject>

/**
 *  See corresponding methods from `SRGTimeSlider`.
 */
- (void)timeSlider:(SRGLetterboxTimeSlider *)slider isMovingToTime:(CMTime)time date:(nullable NSDate *)date withValue:(float)value interactive:(BOOL)interactive;
- (void)timeSlider:(SRGLetterboxTimeSlider *)slider didStartDraggingAtTime:(CMTime)time;
- (void)timeSlider:(SRGLetterboxTimeSlider *)slider didStopDraggingAtTime:(CMTime)time;

@end

NS_ASSUME_NONNULL_END
