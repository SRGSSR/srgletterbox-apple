//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

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
 *  Optional block which gets called right after player creation, when the player changes, or when the configuration is
 *  reloaded by calling `-reloadPlayerConfiguration`. Does not get called when the player is set to `nil`.
 *
 *  @discussion The player starts with external playback disabled and default audio session settings for the media
 *              being played. The configuration block might be used to override these default values.
 */
@property (nonatomic, copy, nullable) void (^playerConfigurationBlock)(AVPlayer *player);

/**
 *  Play the upcoming media currently available.
 *
 *  @return `YES` iff successful.
 */
- (BOOL)playUpcomingMedia;

/**
 *  Ask the player to reload its configuration by calling the associated configuration block, if any. Does nothing if
 *  the player has not been created yet.
 */
- (void)reloadPlayerConfiguration;

/**
 *  Private hook for setting the default content protection to use in Play SRG applications. If not set, defaults to
 *  Akamai token protection.
 */
// FIXME: This hook is temporary until 2019 and must only be used by Play SRG applications. It will be removed
//        afterwards.
+ (void)setDefaultContentProtection:(SRGContentProtection)defaultContentProtection;

@end

NS_ASSUME_NONNULL_END
