//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

// Standard seek intervals
OBJC_EXTERN const NSInteger SRGLetterboxBackwardSeekInterval;
OBJC_EXTERN const NSInteger SRGLetterboxForwardSeekInterval;

@interface SRGLetterboxController : SRGMediaPlayerController

/**
 *  Return YES iff the player can seek backward from a standard amount of seconds
 *
 *  @discussion Always possible for on-demand and DVR streams
 */
- (BOOL)canSeekBackward;

/**
 *  Return YES iff the player can seek forward from a standard amount of seconds
 *
 *  @discussion For on-demand and streams, only possible if seeking wouldn't jump past the end. For DVR streams,
 *              possible until the stream is played live
 */
- (BOOL)canSeekForward;

/**
 *  Seek backward from a standard amount of seconds
 *
 *  @discussion If seeking is not possible or if a seek is interrupted, the completion handler will be called with 
 *              finished set to `NO`
 */
- (void)seekBackwardWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

/**
 *  Seek forward from a standard amount of seconds
 *
 *  @discussion If seeking is not possible or if a seek is interrupted, the completion handler will be called with
 *              finished set to `NO`
 */
- (void)seekForwardWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

@end

NS_ASSUME_NONNULL_END
