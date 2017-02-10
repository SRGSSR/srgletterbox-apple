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
 *  Delegate protocol for picture in picture implementation
 */
@protocol SRGLetterboxPictureInPictureDelegate <NSObject>

/**
 *  Called when picture in picture is started, letting you dismiss the user interface which picture in picture was 
 *  started from
 *
 *  Return YES if you dismissed or began dismissing the user interface from this method (in which case restoration 
 *  methods will be called when picture in picture is exited). The `-letterboxShouldRestoreUserInterfaceForPictureInPicture` 
 *  still lets you control whether the restoration process actually should occur (e.g. if the user interface was dismissed 
 *  but still restored somehow afterwards without picture in picture being exited, most notably if playback moved to another
 *  screen you want to resume to)
 */
- (BOOL)letterboxDismissUserInterfaceForPictureInPicture;

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

@optional

/**
 *  Called when picture in picture has been started
 */
- (void)letterboxDidStartPictureInPicture;

/**
 *  Called when picture in picture stopped
 */
- (void)letterboxDidStopPictureInPicture;

@end

/**
 *  Letterbox media player controller, managing playback, as well as automatic metadata retrieval. Applications
 *  can use the metadata available from this controller to display additional playback information (e.g. title
 *  or description of the content). The controller can be used in isolation for playback without display, but
 *  is usually best used bound to a Letterbox view
 */
@interface SRGLetterboxController : NSObject

/**
 *  Play the specified Uniform Resource Name
 *
 *  @discussion Does nothing if the urn is the one currently being played. The best available quality is automatically
 *              played
 */
- (void)playURN:(SRGMediaURN *)URN;

/**
 *  Play the specified media
 *
 *  @discussion Does nothing if the urn is the one currently being played. The best available quality is automatically
 *              played
 */
- (void)playMedia:(SRGMedia *)media;

/**
 *  Play the specified Uniform Resource Name
 *
 *  @discussion Does nothing if the urn is the one currently being played. If the preferred quality is set to
 *              `SRGQualityNone`, the best available quality will be automatically played
 */
- (void)playURN:(SRGMediaURN *)URN withPreferredQuality:(SRGQuality)preferredQuality;

/**
 *  Play the specified media
 *
 *  @discussion Does nothing if the urn is the one currently being played. If the preferred quality is set to
 *              `SRGQualityNone`, the best available quality will be automatically played
 */
- (void)playMedia:(SRGMedia *)media withPreferredQuality:(SRGQuality)preferredQuality;

/**
 *  Reset playback, stopping a playback request if any has been made
 */
- (void)reset;

/**
 *  Set to YES to mute the player. Default is NO
 */
@property (nonatomic, getter=isMuted) BOOL muted;

@end

/**
 *  Playback information. Changes are notified through `SRGLetterboxMetadataDidChangeNotification` and
 *  `SRGLetterboxPlaybackDidFailNotification`
 */
@interface SRGLetterboxController (PlaybackInformation)

/**
 *  URN
 */
@property (nonatomic, readonly, nullable) SRGMediaURN *URN;

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

@interface SRGLetterboxController (BackgroundServices)

/**
 *  Return YES iff the receiver is enabled for background services
 */
@property (nonatomic, readonly, getter=areBackgroundServicesEnabled) BOOL backgroundServicesEnabled;

/**
 *  Return YES iff the receiver is enabled for picture in picture
 */
@property (nonatomic, readonly, getter=isPictureInPictureEnabled) BOOL pictureInPictureEnabled;

/**
 *  Return YES iff picture in picture is active for the receiver
 */
@property (nonatomic, readonly, getter=isPictureInPictureActive) BOOL pictureInPictureActive;

@end

NS_ASSUME_NONNULL_END
