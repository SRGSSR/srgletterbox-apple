//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxControllerView.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations.
@class SRGControlsView;

/**
 *  Controls view delegate protocol.
 */
@protocol SRGControlsViewDelegate <NSObject>

- (void)controlsView:(SRGControlsView *)controlsView isMovingToPlaybackTime:(CMTime)time withValue:(float)value interactive:(BOOL)interactive;

@end

/**
 *  Internal view class for controls layout.
 */
IB_DESIGNABLE
@interface SRGControlsView : SRGLetterboxControllerView <SRGTimeSliderDelegate>

/**
 *  View optional delegate.
 */
@property (nonatomic, weak, nullable) id<SRGControlsViewDelegate> delegate;

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

NS_ASSUME_NONNULL_END

