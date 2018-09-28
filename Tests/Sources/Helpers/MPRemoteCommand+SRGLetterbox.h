//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <MediaPlayer/MediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPRemoteCommand (SRGLetterbox)

/**
 *  Same as `-addTarget:action:`, but ensures that the provided target is only registered once for a command.
 */
- (void)srg_addUniqueTarget:(id)target action:(SEL)action;

@end

NS_ASSUME_NONNULL_END
