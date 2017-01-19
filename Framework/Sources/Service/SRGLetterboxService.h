//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SRGLetterboxServiceDelegate <NSObject>

/**
 *  Called when picture in picture has been started
 */
- (void)letterboxDidStartPictureInPicture;

/**
 *  Called when picture in picture might need user interface restoration. Return YES if this is the case (most notably
 *  if the player view from which picture in picture was initiated is not visible anymore)
 */
- (BOOL)letterboxShouldRestoreUserInterfaceForPictureInPicture;

/**
 *  Called when a restoration process takes place
 *
 *  @parameter completionHandler A completion block which MUST be called at the VERY END of the restoration process
 *                               (e.g. after at the end of a modal presentation animation). Failing to do so leads to
 *                               undefined behavior. The completion block must be called with `restored` set to `YES`
 *                               iff the restoration was successful
 */
- (void)letterboxRestoreUserInterfaceForPictureInPictureWithCompletionHandler:(void (^)(BOOL restored))completionHandler;

/**
 *  Called when picture in picture stopped
 */
- (void)letterboxDidStopPictureInPicture;

@end

/**
 *  Notification sent when playback metadata is updated (use the dictionary keys below to get previous and new values)
 */
OBJC_EXTERN NSString * const SRGLetterboxServiceMetadataDidChangeNotification;

/**
 *  Current metadata
 */
OBJC_EXTERN NSString * const SRGLetterboxServiceMediaKey;
OBJC_EXTERN NSString * const SRGLetterboxServiceMediaCompositionKey;

/**
 *  Previous metadata
 */
OBJC_EXTERN NSString * const SRGLetterboxServicePreviousMediaKey;
OBJC_EXTERN NSString * const SRGLetterboxServicePreviousMediaCompositionKey;

/**
 *  Notification sent when an error has been encountered. Use the `error` property to get the error itself
 */
OBJC_EXTERN NSString * const SRGLetterboxServicePlaybackDidFailNotification;

/**
 *  Service responsible for media playback. The service itself is a singleton which manages main playback throughout the
 *  application (and associated features like picture in picture, Airplay or control center integration).
 *
 *  @discussion The analytics tracker singleton instance must be started before the singleton instance is accessed for
 *              the first time, otherwise an exception will be thrown in debug builds. Please refer to `SRGAnalyticsTracker`
 *              documentation for more information
 */
@interface SRGLetterboxService : NSObject <AVPictureInPictureControllerDelegate>

/**
 *  The singleton instance
 */
+ (SRGLetterboxService *)sharedService;

/**
 *  Service delegate
 */
@property (nonatomic, weak) id<SRGLetterboxServiceDelegate> delegate;

/**
 *  The controller responsible for playback
 *
 *  @discussion To play medias, use `-playMedia:withDataProvider:preferredQuality:` below. Playing medias directly
 *              on the controller leads to undefined behavior
 */
@property (nonatomic, readonly) SRGLetterboxController *controller;

/**
 *  Play the specified media
 *
 *  @discussion Does nothing if the media is the one currently being played
 */
- (void)playMedia:(SRGMedia *)media withDataProvider:(SRGDataProvider *)dataProvider preferredQuality:(SRGQuality)preferredQuality;

/**
 *  Transfers playback from the specified existing controller to the service. The service media player controller
 *  is replaced
 */
- (void)resumeFromController:(SRGLetterboxController *)controller;

/**
 *  Reset playback, stopping a playback request if any has been made
 */
- (void)reset;

@end

/**
 *  Playback information. Changes are notified through `SRGLetterboxServiceMetadataDidChangeNotification` and
 *  `SRGLetterboxServicePlaybackDidFailNotification`
 */
@interface SRGLetterboxService (PlaybackInformation)

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

@interface SRGLetterboxService (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
