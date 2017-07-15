//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Types.
 */
typedef NSURL * _Nullable (^SRGLetterboxURLOverridingBlock)(SRGMediaURN *URN);

/**
 *  Notification sent when the controller playback state changes. Use the `SRGMediaPlayerPlaybackStateKey` and
 *  `SRGMediaPlayerPreviousPlaybackStateKey` keys to retrieve the current and previous playback states from the
 *  notification `userInfo` dictionary.
 */
OBJC_EXTERN NSString * const SRGLetterboxControllerPlaybackStateDidChangeNotification;

/**
 *  Notification sent when playback metadata is updated (use the dictionary keys below to get previous and new values).
 *
 *  @discussion The data itself should in general change, but the notification might be posted even if no real change
 *              actually occurred. Nevertheless, your implementation should not be concerned about such details and
 *              still respond to change notifications accordingly (e.g. by updating user interface elements).
 */
OBJC_EXTERN NSString * const SRGLetterboxMetadataDidChangeNotification;

/**
 *  Current metadata.
 */
OBJC_EXTERN NSString * const SRGLetterboxURNKey;
OBJC_EXTERN NSString * const SRGLetterboxMediaKey;
OBJC_EXTERN NSString * const SRGLetterboxMediaCompositionKey;
OBJC_EXTERN NSString * const SRGLetterboxSubdivisionKey;
OBJC_EXTERN NSString * const SRGLetterboxChannelKey;

/**
 *  Previous metadata.
 */
OBJC_EXTERN NSString * const SRGLetterboxPreviousURNKey;
OBJC_EXTERN NSString * const SRGLetterboxPreviousMediaKey;
OBJC_EXTERN NSString * const SRGLetterboxPreviousMediaCompositionKey;
OBJC_EXTERN NSString * const SRGLetterboxPreviousSubdivisionKey;
OBJC_EXTERN NSString * const SRGLetterboxPreviousChannelKey;

/**
 *  Notification sent when an error has been encountered.
 */
OBJC_EXTERN NSString * const SRGLetterboxPlaybackDidFailNotification;

/**
 *  Error information.
 */
OBJC_EXTERN NSString * const SRGLetterboxErrorKey;

/**
 *  Notification sent when playback has been retried (might be automatic when network is reachable again).
 */
OBJC_EXTERN NSString * const SRGLetterboxPlaybackDidRetryNotification;

/**
 *  The default start bit rate to start (800 kbps).
 */
OBJC_EXTERN const NSInteger SRGLetterboxDefaultStartBitRate;

/**
 *  The Letterbox controller manages media playback, as well as retrieval and updates of the associated metadata. It 
 *  also takes care of errors, in particular those related to network issues, and automatically resumes when a connection
 *  becomes available.
 *
 *  Applications can use a Letterbox controller to play some content in the background. If they need to display what
 *  is being played, a Letterbox controller needs to be bound to a Letterbox view (@see `SRGLetterboxView`). By integrating
 *  this view into their own hierarchy, and by listening to metadata and error controller notifications, applications can
 *  provide rich playback interfaces with contextual information about the content currently being played.
 *
 *  Letterbox controllers can also be integrated with application-wide features like AirPlay or picture in picture.
 *  Such features can only be enabled for at most one controller at a time by starting the Letterbox service singleton
 *  for this controller (@see `SRGLetterboxService`). Your application is free to use as many controllers as needed, 
 *  though, and you can change at any time which controller is enabled for such services.
 *
 *  When the `SRGAnalytics` tracker singleton has been properly started, controllers are automatically tracked. This
 *  behavior can be disabled by setting the `tracked` property to `NO`. If the tracker singleton has not been started,
 *  analytics won't be collected.
 */
@interface SRGLetterboxController : NSObject

/**
 *  The URL of the service data must be returned from. By default or if reset to `nil`, the production server is
 *  used. Official URL values can be found in `SRGDataProvider.h`.
 */
@property (nonatomic, null_resettable) NSURL *serviceURL;

/**
 *  Prepare to play the specified URN (Uniform Resource Name) with the preferred (non-guaranteed) settings, and with 
 *  the player paused (if playback is not started in the completion handler). If you want playback to start right after 
 *  preparation, call `-play` from the completion handler.
 *
 *  @param URN          The URN to prepare.
 *  @param quality      The quality to use. If `SRGQualityNone` or not found, the best available quality is used.
 *  @param startBitRate The bit rate the media should start playing with, in kbps. This parameter is a recommendation
 *                      with no result guarantee, though it should in general be applied. The nearest available
 *                      quality (larger or smaller than the requested size) will be used. Usual SRG SSR valid bit
 *                      ranges vary from 100 to 3000 kbps. Use 0 to start with the lowest quality stream.
 *  @param completionHandler The completion block to be called after the controller has finished preparing the media. This
 *                           block will only be called if the media could be successfully prepared.
 *
 *  @discussion Does nothing if the URN is the one currently being played.  You might want to set the `resumesAfterRetry` 
 *              property to `NO` when only preparing a player to play.
 */
- (void)prepareToPlayURN:(SRGMediaURN *)URN
    withPreferredQuality:(SRGQuality)quality
            startBitRate:(NSInteger)startBitRate
       completionHandler:(nullable void (^)(void))completionHandler;

/**
 *  Same as `-prepareToPlayURN:withPreferredQuality:startBitRate:completionHandler`, but for a media.
 *
 *  @discussion Media metadata is immediately available from the controller and udpates through notifications.
 */
- (void)prepareToPlayMedia:(SRGMedia *)media
      withPreferredQuality:(SRGQuality)quality
              startBitRate:(NSInteger)startBitRate
         completionHandler:(nullable void (^)(void))completionHandler;

/**
 *  Ask the player to play. If the player has not been prepared, this method does nothing.
 */
- (void)play;

/**
 *  Ask the player to pause playback. Does nothing if the controller is not playing.
 */
- (void)pause;

/**
 *  Ask the controller to change its status from pause to play or conversely, depending on the state it is in.
 */
- (void)togglePlayPause;

/**
 *  Stop playback, keeping playback information.
 */
- (void)stop;

/**
 *  Restart playback completely for the same URN or media. Does nothing if no URN or media has currently been set.
 *
 *  @discussion Whether playback should automatically start when the player is restarted can be controlled using the
 *              `resumesAfterRetry` property.
 */
- (void)restart;

/**
 *  Reset playback and reset all playback information.
 */
- (void)reset;

/**
 *  Set to `YES` to mute the player. Default is `NO`.
 */
@property (nonatomic, getter=isMuted) BOOL muted;

/**
 *  Set to `YES` so that a retry automatically resumes playback (e.g. after a network loss). Default is `YES`.
 */
@property (nonatomic) BOOL resumesAfterRetry;

/**
 *  Set to `YES` to automatically resume playback after the current route becomes unavailalbe (e.g. a wired headset is 
 *  unplugged or a Bluetooth headset is switched off abruptly). Default is `NO`.
 */
@property (nonatomic) BOOL resumesAfterRouteBecomesUnavailable;

@end

@interface SRGLetterboxController (Playback)

/**
 *  The current letterbox controller playback state.
 *
 *  @discussion This property is key-value observable.
 */
@property (nonatomic, readonly) SRGMediaPlayerPlaybackState playbackState;

/**
 *  For DVR and live streams, returns the date corresponding to the current playback time. If the date cannot be
 *  determined or for on-demand streams, the method returns `nil`.
 */
@property (nonatomic, readonly, nullable) NSDate *date;

/**
 *  Return `YES` iff the stream is currently played in live conditions (always `YES` for live streams, `YES` within the 
 *  last 30 seconds of a DVR stream).
 */
@property (nonatomic, readonly, getter=isLive) BOOL live;

/**
 *  The current player time.
 */
@property (nonatomic, readonly) CMTime currentTime;

/**
 *  The current media time range (might be empty or indefinite).
 *
 *  @discussion Use `CMTimeRange` macros for checking time ranges.
 */
@property (nonatomic, readonly) CMTimeRange timeRange;

/**
 *  Register a block for periodic execution when the controller is not in the idle state.
 *
 *  @param interval Time interval between block executions.
 *  @param queue    The serial queue onto which block should be enqueued (main queue if `NULL`).
 *  @param block	The block to be periodically executed.
 *
 *  @return The time observer. The observer is retained by the controller, you can store a weak reference to it and 
 *          remove it at a later time if needed.
 */
- (id)addPeriodicTimeObserverForInterval:(CMTime)interval queue:(nullable dispatch_queue_t)queue usingBlock:(void (^)(CMTime time))block;

/**
 *  Remove a time observer (does nothing if the observer is not registered).
 */
- (void)removePeriodicTimeObserver:(nullable id)observer;

@end

/**
 *  Convenience methods.
 */
@interface SRGLetterboxController (Convenience)

/**
 *  Prepare to play the specified URN (Uniform Resource Name).
 *
 *  @discussion Does nothing if the URN is the one currently being played. The best available quality is automatically
 *              played. The start bit rate is set to `SRGLetterboxDefaultStartBitRate`.
 */
- (void)prepareToPlayURN:(SRGMediaURN *)URN
   withCompletionHandler:(nullable void (^)(void))completionHandler;

/**
 *  Prepare to play the specified media (Uniform Resource Name).
 *
 *  @discussion Does nothing if the media is the one currently being played. The best available quality is automatically
 *              played. The start bit rate is set to `SRGLetterboxDefaultStartBitRate`.
 */
- (void)prepareToPlayMedia:(SRGMedia *)media
     withCompletionHandler:(nullable void (^)(void))completionHandler;

/**
 *  Play the specified URN (Uniform Resource Name).
 *
 *  For more information, @see `-prepareToPlayURN:withPreferredQuality:startBitRate:completionHandler:.
 *
 *  @discussion Does nothing if the media is the one currently being played.
 */
- (void)playURN:(SRGMediaURN *)URN withPreferredQuality:(SRGQuality)quality startBitRate:(NSInteger)startBitRate;

/**
 *  Play the specified media.
 *
 *  For more information, @see `-prepareToPlayMedia:withPreferredQuality:startBitRate:completionHandler:.
 *
 *  @discussion Does nothing if the media is the one currently being played.
 */
- (void)playMedia:(SRGMedia *)media withPreferredQuality:(SRGQuality)quality startBitRate:(NSInteger)startBitRate;

/**
 *  Play the specified URN (Uniform Resource Name).
 *
 *  @discussion Does nothing if the URN is the one currently being played. The best available quality is automatically
 *              played. The start bit rate is set to `SRGLetterboxDefaultStartBitRate`.
 */
- (void)playURN:(SRGMediaURN *)URN;

/**
 *  Play the specified media.
 *
 *  @discussion Does nothing if the URN is the one currently being played. The best available quality is automatically
 *              played. The start bit rate is set to `SRGLetterboxDefaultStartBitRate`.
 */
- (void)playMedia:(SRGMedia *)media;

@end

/**
 *  Playback information. Changes are notified through `SRGLetterboxMetadataDidChangeNotification` and
 *  `SRGLetterboxPlaybackDidFailNotification`.
 */
@interface SRGLetterboxController (Metadata)

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
 *  Channel information (contains information about current and next programs).
 */
@property (nonatomic, readonly, nullable) SRGChannel *channel;

/**
 *  The current subdivision being played (if any).
 */
@property (nonatomic, readonly, nullable) SRGSubdivision *subdivision;

/**
 *  The current subdivision (segment or chapter) being played, if any, as an `SRGMedia` object.
 */
@property (nonatomic, readonly, nullable) SRGMedia *subdivisionMedia;

/**
 *  The current full-length information (if available).
 */
@property (nonatomic, readonly, nullable) SRGMedia *fullLengthMedia;

/**
 *  Error (if any has been encountered).
 */
@property (nonatomic, readonly, nullable) NSError *error;

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

/**
 *  Settings for SRGAnalytics integration.
 */
@interface SRGLetterboxController (Analytics)

/**
 *  Streaming analytics are automatically gathered when this property is set to `YES` (default).
 */
@property (nonatomic, getter=isTracked) BOOL tracked;

@end

/**
 *  Settings for periodic updates.
 */
@interface SRGLetterboxController (PeriodicUpdates)

/**
 *  Time interval between stream availability checks. Live streams might change (e.g. if a stream is toggled between DVR 
 *  and live-only versions) or not be available anymore (e.g. if the location of the user changes and the stream is not
 *  available for the new location). If a stream is changed, the new one is automatically played, otherwise playback
 *  stops with an error.
 *
 *  Default is 5 minutes, and minimum is 10 seconds.
 */
@property (nonatomic) NSTimeInterval streamAvailabilityCheckInterval;

/**
 *  Time interval between now and next information updates, notified by a `SRGLetterboxMetadataDidChangeNotification`
 *  notification.
 *
 *  Default is 30 seconds, and minimum is 10 seconds.
 */
@property (nonatomic) NSTimeInterval channelUpdateInterval;

@end

/**
 *  Overriding abilities. Player functionalities might be limited when overriding has been made.
 */
@interface SRGLetterboxController (Overriding)

/**
 *  Provides a way to override the content URL which has been retrieved for a media. This is for example useful
 *  to replace the original URL with a local file URL. Content overriding takes place when a play request is
 *  initiated, content overriding must be setup before such requests are made, otherwise it won't take place.
 *
 *  @discussion When a URL has been overridden, the player will only work with the media, not the full playback
 *              context (since the context is tightly related to the original content URL, this would open the
 *              door to several inconsistencies, most notably with segments)
 */
@property (nonatomic, copy, nullable) SRGLetterboxURLOverridingBlock contentURLOverridingBlock;

/**
 *  Return `YES` iff the URL played by the controller is overridden.
 *
 *  @discussion If no media URN is attached to the controller, the property returns `NO`.  
 */
@property (nonatomic, readonly, getter=isContentURLOverridden) BOOL contentURLOverridden;

@end

NS_ASSUME_NONNULL_END
