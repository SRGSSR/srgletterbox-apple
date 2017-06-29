//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Standard skip intervals.
 */
OBJC_EXTERN const NSInteger SRGLetterboxBackwardSkipInterval;
OBJC_EXTERN const NSInteger SRGLetterboxForwardSkipInterval;

/**
 *  Interface for internal use.
 */
@interface SRGLetterboxController (Private)

/**
 *  The media player controller managing playback.
 *
 *  @discussion Do not alter properties of this player controller, this could lead to undefined behavior. Only use
 *              in a readonly way or to register observers.
 */
@property (nonatomic, readonly) SRGMediaPlayerController *mediaPlayerController;

/**
 *  Switch to the specified subdivision (segment or chapter) of the current media. Does nothing if no media composition 
 *  is available yet, or if the subdivision is not related to the media composition. Playback is automatically resumed if 
 *  necessary.
 *
 *  Return `YES` iff switching is possible.
 */
- (BOOL)switchToSubdivision:(SRGSubdivision *)subdivision;

/**
 *  Return YES iff the player can skip backward from a standard amount of seconds.
 *
 *  @discussion Always possible for on-demand and DVR streams.
 */
- (BOOL)canSkipBackward;

/**
 *  Return YES iff the player can skip forward from a standard amount of seconds.
 *
 *  @discussion For on-demand and streams, only possible if seeking wouldn't jump past the end. For DVR streams,
 *              possible until the stream is played live.
 */
- (BOOL)canSkipForward;

/**
 *  Return YES iff the player can skip to live conditions.
 */
- (BOOL)canSkipToLive;

/**
 *  Skip backward from a standard amount of seconds.
 *
 *  @discussion If skipping is not possible or if a skip is interrupted, the completion handler will be called with
 *              finished set to `NO`.
 */
- (void)skipBackwardWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

/**
 *  Skip forward from a standard amount of seconds.
 *
 *  @discussion If skipping is not possible or if a skip is interrupted, the completion handler will be called with
 *              finished set to `NO`.
 */
- (void)skipForwardWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

/**
 *  Skip forward to live conditions.
 *
 *  @discussion If skipping is not possible or if a skip is interrupted, the completion handler will be called with
 *              finished set to `NO`.
 */
- (void)skipToLiveWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

/**
 *  Optional block which gets called right after player creation, when the player changes, or when the configuration is
 *  reloaded by calling `-reloadPlayerConfiguration`. Does not get called when the player is set to `nil`.
 *
 *  @discussion The player starts with external playback disabled and default audio session settings for the media
 *              being played. The configuration block might be used to override these default values.
 */
@property (nonatomic, copy, nullable) void (^playerConfigurationBlock)(AVPlayer *player);

/**
 *  Ask the player to reload its configuration by calling the associated configuration block, if any. Does nothing if
 *  the player has not been created yet.
 */
- (void)reloadPlayerConfiguration;

@end

NS_ASSUME_NONNULL_END
