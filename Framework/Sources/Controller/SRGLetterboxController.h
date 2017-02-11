//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Notification sent when playback metadata is updated (use the dictionary keys below to get previous and new values)
 */
OBJC_EXTERN NSString * const SRGLetterboxMetadataDidChangeNotification;

/**
 *  Current metadata
 */
OBJC_EXTERN NSString * const SRGLetterboxURNKey;
OBJC_EXTERN NSString * const SRGLetterboxMediaKey;
OBJC_EXTERN NSString * const SRGLetterboxMediaCompositionKey;

/**
 *  Previous metadata
 */
OBJC_EXTERN NSString * const SRGLetterboxPreviousURNKey;
OBJC_EXTERN NSString * const SRGLetterboxPreviousMediaKey;
OBJC_EXTERN NSString * const SRGLetterboxPreviousMediaCompositionKey;

/**
 *  Notification sent when an error has been encountered
 */
OBJC_EXTERN NSString * const SRGLetterboxPlaybackDidFailNotification;

/**
 *  Error information
 */
OBJC_EXTERN NSString * const SRGLetterboxErrorKey;

/**
 *  The Letterbox controller manages media playback, as well as retrieval and updates of the associated metadata. It 
 *  also takes care of errors, in particular those related to network issues, and automatically resumes when a connection
 *  becomes available.
 *
 *  Applications can use a Letterbox controller to play some content in the background. If they need to display what
 *  is being played, a Letterbox controller needs to be bound to a Letterbox view (@see `SRGLetterboxView`). By integrating
 *  this view into their own hierarchy, and by listening to metadata and error controller notitications, applications can 
 *  provide rich playback interfaces with contextual information about the content currently being played.
 *
 *  Letterbox controllers can also be integrated with application-wide features like Airplay or picture in picture.
 *  Such features can only be enabled for at most one controller at a time by starting the Letterbox service singleton
 *  for this controller (@see `SRGLetterboxService`). Your application is free to use as many controllers as needed, 
 *  though, and you can change at any time which controller is enabled for such services.
 */
@interface SRGLetterboxController : NSObject

/**
 *  Play the specified URN (Uniform Resource Name).
 *
 *  @discussion Does nothing if the URN is the one currently being played. The best available quality is automatically
 *              played.
 */
- (void)playURN:(SRGMediaURN *)URN;

/**
 *  Play the specified media.
 *
 *  @discussion Does nothing if the URN is the one currently being played. The best available quality is automatically
 *              played.
 */
- (void)playMedia:(SRGMedia *)media;

/**
 *  Play the specified URN (Uniform Resource Name).
 *
 *  @discussion Does nothing if the URN is the one currently being played. If the preferred quality is set to
 *              `SRGQualityNone`, the best available quality will be automatically played.
 */
- (void)playURN:(SRGMediaURN *)URN withPreferredQuality:(SRGQuality)preferredQuality;

/**
 *  Play the specified media.
 *
 *  @discussion Does nothing if the media is the one currently being played. If the preferred quality is set to
 *              `SRGQualityNone`, the best available quality will be automatically played.
 */
- (void)playMedia:(SRGMedia *)media withPreferredQuality:(SRGQuality)preferredQuality;

/**
 *  Reset playback, stopping a playback request if any has been made.
 */
- (void)reset;

/**
 *  Set to `YES` to mute the player. Default is `NO`.
 */
@property (nonatomic, getter=isMuted) BOOL muted;

@end

/**
 *  Playback information. Changes are notified through `SRGLetterboxMetadataDidChangeNotification` and
 *  `SRGLetterboxPlaybackDidFailNotification`.
 */
@interface SRGLetterboxController (PlaybackInformation)

/**
 *  Unified Resource Name of the media being played.
 */
@property (nonatomic, readonly, nullable) SRGMediaURN *URN;

/**
 *  Media information.
 */
@property (nonatomic, readonly, nullable) SRGMedia *media;

/**
 *  Media composition (playback context).
 */
@property (nonatomic, readonly, nullable) SRGMediaComposition *mediaComposition;

/**
 *  Error (if any has been encountered).
 */
@property (nonatomic, readonly) NSError *error;

@end

/**
 *  Services information. Use `SRGLetterboxService` to start application-wide services for a Letterbox controller.
 */
@interface SRGLetterboxController (Services)

/**
 *  Return `YES` iff the receiver is enabled for background services.
 */
@property (nonatomic, readonly, getter=areBackgroundServicesEnabled) BOOL backgroundServicesEnabled;

/**
 *  Return `YES` iff the receiver is enabled for picture in picture.
 */
@property (nonatomic, readonly, getter=isPictureInPictureEnabled) BOOL pictureInPictureEnabled;

/**
 *  Return `YES` iff picture in picture is currently active for the receiver.
 */
@property (nonatomic, readonly, getter=isPictureInPictureActive) BOOL pictureInPictureActive;

@end

NS_ASSUME_NONNULL_END
