//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Standard seek intervals.
 */
OBJC_EXTERN const NSInteger SRGLetterboxBackwardSeekInterval;
OBJC_EXTERN const NSInteger SRGLetterboxForwardSeekInterval;

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
 *  Return YES iff the player can seek backward from a standard amount of seconds.
 *
 *  @discussion Always possible for on-demand and DVR streams.
 */
- (BOOL)canSeekBackward;

/**
 *  Return YES iff the player can seek forward from a standard amount of seconds.
 *
 *  @discussion For on-demand and streams, only possible if seeking wouldn't jump past the end. For DVR streams,
 *              possible until the stream is played live.
 */
- (BOOL)canSeekForward;

/**
 *  Return YES iff the player can seek to play live
 *
 *  @discussion For live stream only, and only possible if seeking wouldn't jump past the end. For DVR streams,
 *              possible until the stream is played live.
 */
- (BOOL)canSeekToLive;

/**
 *  Seek backward from a standard amount of seconds.
 *
 *  @discussion If seeking is not possible or if a seek is interrupted, the completion handler will be called with
 *              finished set to `NO`.
 */
- (void)seekBackwardWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

/**
 *  Seek forward from a standard amount of seconds.
 *
 *  @discussion If seeking is not possible or if a seek is interrupted, the completion handler will be called with
 *              finished set to `NO`.
 */
- (void)seekForwardWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

/**
 *  Seek forward to live conditions.
 *
 *  @discussion If seeking is not possible or if a seek is interrupted, the completion handler will be called with
 *              finished set to `NO`.
 */
- (void)seekToLiveWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

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
