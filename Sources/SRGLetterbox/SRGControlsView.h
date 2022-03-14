//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxControllerView.h"

@import SRGMediaPlayer;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

// Forward declarations.
@class SRGControlsView;

/**
 *  Controls view delegate protocol.
 */
API_UNAVAILABLE(tvos)
@protocol SRGControlsViewDelegate <NSObject>

/**
 *  Method called when the user did tap on the controls view.
 */
- (void)controlsViewDidTap:(SRGControlsView *)controlsView;

/**
 *  Implement to return `YES` iff the full screen button must be shown.
 *
 *  @discussion If no delegate has been defined, the default behavior is `NO`.
 */
- (BOOL)controlsViewShouldHideFullScreenButton:(SRGControlsView *)controlsView;

/**
 *  Method called when the user toggles full screen using the dedicated button.
 */
- (void)controlsViewDidToggleFullScreen:(SRGControlsView *)controlsView;

/**
 *  Method called when the time slider moved, either interactively or during normal playback.
 */
- (void)controlsView:(SRGControlsView *)controlsView isMovingSliderToTime:(CMTime)time date:(nullable NSDate *)date withValue:(float)value interactive:(BOOL)interactive;

/**
 *  Method called when the playback settings are about to be shown.
 */
- (void)controlsViewWillShowPlaybackSettings:(SRGControlsView *)controlsView;

/**
 *  Method called when the playback settings have been hidden.
 */
- (void)controlsViewDidHidePlaybackSettings:(SRGControlsView *)controlsView;

@end

/**
 *  View displaying controls.
 */
API_UNAVAILABLE(tvos)
@interface SRGControlsView : SRGLetterboxControllerView <SRGTimeSliderDelegate, SRGPlaybackSettingsButtonDelegate>

/**
 *  View optional delegate.
 */
@property (nonatomic, weak, nullable) id<SRGControlsViewDelegate> delegate;

/**
 *  The style to be applied for the view and views depending on it, like the playback settings popover. The default value is
 *  `SRGMediaPlayerUserInterfaceStyleUnspecified`.
 *
 *  @discussion Style changes might be applied at a later time.
 */
@property (nonatomic) SRGMediaPlayerUserInterfaceStyle userInterfaceStyle;

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

