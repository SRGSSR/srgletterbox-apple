//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Notification sent when playback metadata is updated (use the dictionary keys below to get previous and new values)
 */
OBJC_EXTERN NSString * const SRGMediaServiceMetadataDidChangeNotification;

/**
 *  Current metadata
 */
OBJC_EXTERN NSString * const SRGMediaServiceMediaKey;
OBJC_EXTERN NSString * const SRGMediaServiceMediaCompositionKey;

/**
 *  Previous metadata
 */
OBJC_EXTERN NSString * const SRGMediaServicePreviousMediaKey;
OBJC_EXTERN NSString * const SRGMediaServicePreviousMediaCompositionKey;

/**
 *  Notification sent when an error has been encountered. Use the `error` property to get the error itself
 */
OBJC_EXTERN NSString * const SRGMediaServicePlaybackDidFailNotification;

@interface SRGMediaService : NSObject <AVPictureInPictureControllerDelegate>

/**
 *  Main default instance. This instance is responsible for managing current playback and the associated features:
 *    - Background playback
 *    - Picture in picture
 *    - Airplay
 *    - Control center integration and picture in picture support
 */
+ (SRGMediaService *)sharedSRGMediaService;

/**
 *  The controller responsible for playback
 */
@property (nonatomic, readonly) SRGLetterboxController *controller;

/**
 *  Play the specified media
 *
 *  @discussion Does nothing if the media is the one currently being played
 */
- (void)playMedia:(SRGMedia *)media preferredQuality:(SRGQuality)quality;

/**
 *  Transfers playback from the specified existing controller to the service. The service media player controller
 *  is replaced
 *
 *  @return YES iff resuming could be successfully made
 */
- (BOOL)resumeFromSRGLetterboxController:(SRGLetterboxController *)controller;

/**
 *  Reset playback, stopping a playback request if any has been made
 */
- (void)reset;

@end

/**
 *  Playback information. Changes are notified through `SRGMediaServiceMetadataDidChangeNotification` and
 *  `SRGMediaServicePlaybackDidFailNotification`
 */
@interface SRGMediaService (PlaybackInformation)

/**
 *  Media information
 */
@property (nonatomic, readonly, nullable) SRGMedia *media;

/**
 *  Media composition
 */
@property (nonatomic, readonly, nullable) SRGMediaComposition *mediaComposition;

/**
 *  Error if any has been encountered
 */
@property (nonatomic, readonly) NSError *error;

@end

@interface SRGMediaService (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
