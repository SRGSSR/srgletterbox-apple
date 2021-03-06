//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

@import SRGMediaPlayer;

NS_ASSUME_NONNULL_BEGIN

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

/**
 *  Return the displayable subdivision (segment or chapter) at the specified time, `nil` if none.
 */
- (nullable SRGSubdivision *)displayableSubdivisionAtTime:(CMTime)time;

/**
 *  The current media which can be used for display purposes (thumbnails, control center…)
 */
@property (nonatomic, readonly, nullable) SRGMedia *displayableMedia;

@end

NS_ASSUME_NONNULL_END
