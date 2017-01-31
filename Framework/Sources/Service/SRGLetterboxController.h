//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>
#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

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
 *  Lightweight `SRGMediaPlayerController` subclass. This class exposes only standard Letterbox functionalities, and inhibits
 *  some `SRGMediaPlayerController` behaviors.
 */
@interface SRGLetterboxController : SRGMediaPlayerController

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
 *  Only playback of media compositions is available on the Letterbox controller
 */
@interface SRGLetterboxController (Unavailable)

- (void)prepareToPlayURL:(NSURL *)URL
                  atTime:(CMTime)time
            withSegments:(nullable NSArray<id<SRGSegment>> *)segments
                userInfo:(nullable NSDictionary *)userInfo
       completionHandler:(nullable void (^)(void))completionHandler NS_UNAVAILABLE;

- (void)prepareToPlayURL:(NSURL *)URL withCompletionHandler:(nullable void (^)(void))completionHandler NS_UNAVAILABLE;

- (void)playURL:(NSURL *)URL
         atTime:(CMTime)time
   withSegments:(nullable NSArray<id<SRGSegment>> *)segments
       userInfo:(nullable NSDictionary *)userInfo NS_UNAVAILABLE;

- (void)prepareToPlayURL:(NSURL *)URL
                 atIndex:(NSInteger)index
              inSegments:(NSArray<id<SRGSegment>> *)segments
            withUserInfo:(nullable NSDictionary *)userInfo
       completionHandler:(nullable void (^)(void))completionHandler NS_UNAVAILABLE;

- (void)playURL:(NSURL *)URL
        atIndex:(NSInteger)index
     inSegments:(NSArray<id<SRGSegment>> *)segments
   withUserInfo:(nullable NSDictionary *)userInfo NS_UNAVAILABLE;

- (void)playURL:(NSURL *)URL
         atTime:(CMTime)time
   withSegments:(nullable NSArray<id<SRGSegment>> *)segments
analyticsLabels:(nullable NSDictionary *)analyticsLabels
       userInfo:(nullable NSDictionary *)userInfo NS_UNAVAILABLE;

- (void)prepareToPlayURL:(NSURL *)URL
                 atIndex:(NSInteger)index
              inSegments:(NSArray<id<SRGSegment>> *)segments
     withAnalyticsLabels:(nullable NSDictionary *)analyticsLabels
                userInfo:(nullable NSDictionary *)userInfo
       completionHandler:(nullable void (^)(void))completionHandler NS_UNAVAILABLE;

- (void)playURL:(NSURL *)URL
        atIndex:(NSInteger)index
     inSegments:(NSArray<id<SRGSegment>> *)segments
withAnalyticsLabels:(nullable NSDictionary *)analyticsLabels
       userInfo:(nullable NSDictionary *)userInfo NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
