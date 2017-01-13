//
//  Copyright (c) SRG. All rights reserved.
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
 */
- (BOOL)canSeekBackward;

/**
 *  Return YES iff the player can seek forward from a standard amount of seconds
 */
- (BOOL)canSeekForward;

/**
 *  Seek backward from a standard amount of seconds
 */
- (void)seekBackwardWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

/**
 *  Seek forward from a standard amount of seconds
 */
- (void)seekForwardWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

@end

NS_ASSUME_NONNULL_END
