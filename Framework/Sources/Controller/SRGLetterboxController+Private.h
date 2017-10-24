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
 *  Notification sent when a live stream in the media composition is over. Use `SRGLetterboxMediaKey` to have the concerned media.
 */
OBJC_EXTERN NSString * const SRGLetterboxPlaybackLiveStreamIsOverNotification;

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
 *  Return `YES` iff the player can skip backward from a standard amount of seconds.
 *
 *  @discussion Always possible for on-demand and DVR streams.
 */
- (BOOL)canSkipBackward;

/**
 *  Return `YES` iff the player can skip forward from a standard amount of seconds.
 *
 *  @discussion For on-demand and streams, only possible if seeking wouldn't jump past the end. For DVR streams,
 *              possible until the stream is played live.
 */
- (BOOL)canSkipForward;

/**
 *  Return `YES` iff the player can skip to live conditions.
 */
- (BOOL)canSkipToLive;

/**
 *  Skip backward from a standard amount of seconds.
 *
 *  @param completionHandler The completion handler called once skipping finishes. The block will only be called when
 *                           skipping is attempted, and with `finished` set to `YES` iff skipping was not interrupted.
 *
 *  @return `YES` iff skipping is possible.
 */
- (BOOL)skipBackwardWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

/**
 *  Skip forward from a standard amount of seconds.
 *
 *  @param completionHandler The completion handler called once skipping finishes. The block will only be called when
 *                           skipping is attempted, and with `finished` set to `YES` iff skipping was not interrupted.
 *
 *  @return `YES` iff skipping is possible.
 */
- (BOOL)skipForwardWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

/**
 *  Skip forward to live conditions.
 *
 *  @param completionHandler The completion handler called once skipping finishes. The block will only be called when
 *                           skipping is attempted, and with `finished` set to `YES` iff skipping was not interrupted.
 *
 *  @return `YES` iff skipping is possible.
 */
- (BOOL)skipToLiveWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

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
