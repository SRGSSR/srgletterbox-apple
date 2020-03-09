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
static const NSTimeInterval SRGLetterboxBackwardSkipInterval = 10.;
static const NSTimeInterval SRGLetterboxForwardSkipInterval = 30.;

/**
 *  Notification sent when the livestream associated with the current playback context just finished. The corresponding
 *  media can be retrieved under the `SRGLetterboxMediaKey` user information key.
 */
OBJC_EXPORT NSString * const SRGLetterboxLivestreamDidFinishNotification;

/**
 *  Notification sent when a request to the social count view service will be fired. The corresponding media subdivision
 *  can be retrieved under the `SRGLetterboxSubdivisionKey` user information key.
 */
OBJC_EXPORT NSString * const SRGLetterboxSocialCountViewWillIncreaseNotification;

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
 *  The program corresponding to the current playback position, if any.
 */
@property (nonatomic, readonly, nullable) SRGProgram *program;

/**
 *  Play the upcoming media currently available.
 *
 *  @return `YES` iff successful.
 */
- (BOOL)playUpcomingMedia;

/**
 *  Enable or disable external playback, with or without automatic switching to an external screen (ignored if external
 *  playback is disaabled).
 *
 *  By default external playback is disabled.
 */
- (void)setAllowsExternalPlayback:(BOOL)allowsExternalPlayback usedWhileExternalScreenIsActive:(BOOL)usesWhileExternalScreenIsActive;

/**
 *  Returns `YES` iff the controller is currently used for external AirPlay playback.
 */
@property (nonatomic, readonly, getter=isUsingAirPlay) BOOL usingAirPlay;

@end

NS_ASSUME_NONNULL_END
