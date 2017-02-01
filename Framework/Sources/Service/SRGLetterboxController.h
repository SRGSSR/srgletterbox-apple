//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVKit/AVKit.h>
#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Standard seek intervals
 */
OBJC_EXTERN const NSInteger SRGLetterboxBackwardSeekInterval;
OBJC_EXTERN const NSInteger SRGLetterboxForwardSeekInterval;

/**
 *  Notification sent when playback metadata is updated (use the dictionary keys below to get previous and new values)
 */
OBJC_EXTERN NSString * const SRGLetterboxMetadataDidChangeNotification;

/**
 *  Current metadata
 */
OBJC_EXTERN NSString * const SRGLetterboxPreviousURNKey;
OBJC_EXTERN NSString * const SRGLetterboxMediaKey;
OBJC_EXTERN NSString * const SRGLetterboxMediaCompositionKey;
OBJC_EXTERN NSString * const SRGLetterboxPreferredQualityKey;

/**
 *  Previous metadata
 */
OBJC_EXTERN NSString * const SRGLetterboxPreviousURNKey;
OBJC_EXTERN NSString * const SRGLetterboxPreviousMediaKey;
OBJC_EXTERN NSString * const SRGLetterboxPreviousMediaCompositionKey;
OBJC_EXTERN NSString * const SRGLetterboxPreferredQualityKey;

/**
 *  Notification sent when an error has been encountered. Use the `error` property to get the error itself
 */
OBJC_EXTERN NSString * const SRGLetterboxPlaybackDidFailNotification;

/**
 *  Delegate protocol for picture in picture implementation
 */
@protocol SRGLetterboxPictureInPictureDelegate <NSObject>

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
@interface SRGLetterboxController : NSObject <AVPictureInPictureControllerDelegate>

/**
 *  Play the specified Uniform Resource Name
 *
 *  @discussion Does nothing if the urn is the one currently being played
 */
- (void)playURN:(SRGMediaURN *)URN withPreferredQuality:(SRGQuality)preferredQuality;

/**
 *  Play the specified media
 *
 *  @discussion Does nothing if the media is the one currently being played
 */
- (void)playMedia:(SRGMedia *)media withPreferredQuality:(SRGQuality)preferredQuality;

/**
 *  Reset playback, stopping a playback request if any has been made
 */
- (void)reset;

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

/**
 *  Picture in picture support. Implement `SRGLetterboxPictureInPictureDelegate` methods to integrate Letterbox picture in picture
 *  support within your application
 */
@interface SRGLetterboxController (PictureInPicture)

/**
 *  Picture in picture delegate. Picture in picture won't be available if not set
 */
@property (nonatomic, weak) id<SRGLetterboxPictureInPictureDelegate> pictureInPictureDelegate;

/**
 *  Return YES iff picture in picture is active
 */
@property (nonatomic, readonly, getter=isPictureInPictureActive) BOOL pictureInPictureActive;

@end

NS_ASSUME_NONNULL_END
