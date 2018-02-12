//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Controller data availability.
 */
typedef NS_ENUM(NSInteger, SRGLetterboxDataAvailability) {
    /**
     *  No data is available.
     */
    SRGLetterboxDataAvailabilityNone,
    /**
     *  Data is being loaded.
     */
    SRGLetterboxDataAvailabilityLoading,
    /**
     *  Data has been loaded once.
     */
    SRGLetterboxDataAvailabilityLoaded
};

/**
 *  Types.
 */
typedef NSURL * _Nullable (^SRGLetterboxURLOverridingBlock)(SRGMediaURN *URN);

/**
 *  Notification sent when the controller playback state changes. Use the `SRGMediaPlayerPlaybackStateKey` and
 *  `SRGMediaPlayerPreviousPlaybackStateKey` keys to retrieve the current and previous playback states from the
 *  notification `userInfo` dictionary.
 */
OBJC_EXPORT NSString * const SRGLetterboxPlaybackStateDidChangeNotification;

/**
 *  Notification sent when playback metadata is updated (use the dictionary keys below to get previous and new values).
 *
 *  @discussion The data itself should in general change, but the notification might be posted even if no real change
 *              actually occurred. Nevertheless, your implementation should not be concerned about such details and
 *              still respond to change notifications accordingly (e.g. by updating user interface elements).
 */
OBJC_EXPORT NSString * const SRGLetterboxMetadataDidChangeNotification;

/**
 *  Current metadata.
 */
OBJC_EXPORT NSString * const SRGLetterboxURNKey;
OBJC_EXPORT NSString * const SRGLetterboxMediaKey;
OBJC_EXPORT NSString * const SRGLetterboxMediaCompositionKey;
OBJC_EXPORT NSString * const SRGLetterboxSubdivisionKey;
OBJC_EXPORT NSString * const SRGLetterboxChannelKey;

/**
 *  Previous metadata.
 */
OBJC_EXPORT NSString * const SRGLetterboxPreviousURNKey;
OBJC_EXPORT NSString * const SRGLetterboxPreviousMediaKey;
OBJC_EXPORT NSString * const SRGLetterboxPreviousMediaCompositionKey;
OBJC_EXPORT NSString * const SRGLetterboxPreviousSubdivisionKey;
OBJC_EXPORT NSString * const SRGLetterboxPreviousChannelKey;

/**
 *  Notification sent when an error has been encountered.
 */
OBJC_EXPORT NSString * const SRGLetterboxPlaybackDidFailNotification;

/**
 *  Error information.
 */
OBJC_EXPORT NSString * const SRGLetterboxErrorKey;

/**
 *  Notification sent when playback has been retried (might be automatic when network is reachable again).
 */
OBJC_EXPORT NSString * const SRGLetterboxPlaybackDidRetryNotification;

/**
 *  The default start bit rate to start (800 kbps).
 */
OBJC_EXPORT const NSInteger SRGLetterboxDefaultStartBitRate;

/**
 *  Time interval for stream availability checks. Default is 30 seconds.
 */
OBJC_EXPORT const NSTimeInterval SRGLetterboxUpdateIntervalDefault;

/**
 *  Time interval to check channel metadata. Default is 30 seconds.
 */
OBJC_EXPORT const NSTimeInterval SRGLetterboxChannelUpdateIntervalDefault;

/**
 *  Standard skip intervals.
 */
OBJC_EXPORT const NSTimeInterval SRGLetterboxBackwardSkipInterval;           // 10 seconds
OBJC_EXPORT const NSTimeInterval SRGLetterboxForwardSkipInterval;            // 30 seconds

/**
 *  Standard intervals before automatically playing the next item in a playlist.
 */
OBJC_EXPORT const NSTimeInterval SRGLetterboxContinuousPlaybackDelayDefault;           // 5 seconds
OBJC_EXPORT const NSTimeInterval SRGLetterboxContinuousPlaybackDelayImmediate;         // 0 seconds
OBJC_EXPORT const NSTimeInterval SRGLetterboxContinuousPlaybackDelayDisabled;          // Disable continuous playback

/**
 *  Forward declarations.
 */
@class SRGLetterboxController;

/**
 *  A playlist data source provides next and previous medias to be played by a controller.
 *
 *  @discussion Since a controller can play any content at any time, there is no way for an implementation to guess
 *              where it must resume if the content appears more than once. For this reason, playlist implementations
 *              should contain a given media at most once (otherwise the playlist behavior will likely be undefined).
 *
 *              If continuous playback is enabled (default behavior), implementations should not alter the playlist
 *              next item while playback is about to resume with the next item (see `continuousPlaybackDelay`), otherwise
 *              the behavior is undefined.
 */
@protocol SRGLetterboxControllerPlaylistDataSource <NSObject>

/**
 *  The next media to be played.
 */
- (nullable SRGMedia *)nextMediaForController:(SRGLetterboxController *)controller;

/**
 *  The previous media to be played.
 */
- (nullable SRGMedia *)previousMediaForController:(SRGLetterboxController *)controller;

@end

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
 *
 *  @discussion Changing the service URL while playing is possible, but the change is not guaranteed to be applied
 *              immediately, and playback might be interrupted if the new service is not available to provide data
 *              for the media being played. In general, and a different service URL is required, you should therefore 
 *              set it before starting playback.
 */
@property (nonatomic, null_resettable) NSURL *serviceURL;

/**
 *  Prepare to play the specified URN (Uniform Resource Name) with the preferred (non-guaranteed) settings, and with 
 *  the player paused (if playback is not started in the completion handler). If you want playback to start right after 
 *  preparation, call `-play` from the completion handler.
 *
 *  @param URN               The URN to prepare.
 *  @param streamType        The stream type to use. If `SRGStreamTypeNone` or not found, the optimal available stream
 *                           type is used.
 *  @param quality           The quality to use. If `SRGQualityNone` or not found, the best available quality is used.
 *  @param startBitRate      The bit rate the media should start playing with, in kbps. This parameter is a recommendation
 *                           with no result guarantee, though it should in general be applied. The nearest available
 *                           quality (larger or smaller than the requested size) will be used. Usual SRG SSR valid bit
 *                           ranges vary from 100 to 3000 kbps. Use 0 to start with the lowest quality stream.
 *  @param chaptersOnly      If set to `YES`, only chapters will be played, otherwise a possible mixture of chapters and
 *                           segments.
 *  @param completionHandler The completion block to be called after the controller has finished preparing the media. This
 *                           block will only be called if the media could be successfully prepared.
 *
 *  @discussion Does nothing if the URN is the one currently being played. You might want to set the `resumesAfterRetry` 
 *              property to `NO` when only preparing a player to play.
 */
- (void)prepareToPlayURN:(SRGMediaURN *)URN
 withPreferredStreamType:(SRGStreamType)streamType
                 quality:(SRGQuality)quality
            startBitRate:(NSInteger)startBitRate
            chaptersOnly:(BOOL)chaptersOnly
       completionHandler:(nullable void (^)(void))completionHandler;

/**
 *  Same as `-prepareToPlayURN:withPreferredStreamType:quality:startBitRate:completionHandler`, but for a media.
 *
 *  @discussion Media metadata is immediately available from the controller and udpates through notifications.
 */
- (void)prepareToPlayMedia:(SRGMedia *)media
   withPreferredStreamType:(SRGStreamType)streamType
                   quality:(SRGQuality)quality
              startBitRate:(NSInteger)startBitRate
              chaptersOnly:(BOOL)chaptersOnly
         completionHandler:(nullable void (^)(void))completionHandler;

/**
 *  Ask the player to play. 
 *
 *  @discussion Start playback if a media is available and the player is idle.
 */
- (void)play;

/**
 *  Ask the player to pause playback. Does nothing if the controller is not playing.
 */
- (void)pause;

/**
 *  Ask the controller to change its status from pause to play or conversely, depending on the state it is in. 
 *
 *  @discussion Start playback if a media is available and the player is idle.
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
 *  Reset playback and all playback information.
 */
- (void)reset;

/**
 *  Ask the controller to seek to a given location. A paused player remains paused, while a playing player remains
 *  playing. You can use the completion handler to change the player state if needed, e.g. to automatically
 *  resume playback after a seek has been performed on a paused player.
 *
 *  @param time              The time to start at. If the time is invalid it will be set to `kCMTimeZero`. Setting a 
 *                           start time outside the actual media time range will seek to the nearest location (either 
 *                           zero or the end time).
 *  @param toleranceBefore   The tolerance allowed before `time`. Use `kCMTimePositiveInfinity` for no tolerance
 *                           requirements.
 *  @param toleranceAfter    The tolerance allowed after `time`. Use `kCMTimePositiveInfinity` for no tolerance
 *                           requirements.
 *  @param completionHandler The completion handler called when the seek ends. If the seek has been interrupted by
 *                           another seek, the completion handler will be called with `finished` set to `NO`, otherwise
 *                           with `finished` set to `YES`.
 *
 *  @discussion Upon completion handler entry, the playback state will be up-to-date if the seek finished, otherwise
 *              the player will still be in the seeking state. Note that if the media was not ready to play, seeking
 *              won't take place, and the completion handler won't be called.
 */
- (void)seekToTime:(CMTime)time
withToleranceBefore:(CMTime)toleranceBefore
    toleranceAfter:(CMTime)toleranceAfter
 completionHandler:(nullable void (^)(BOOL finished))completionHandler;

/**
 *  Switch to the specified URN, resuming playback if necessary. The URN must be related to the current playback context
 *  (i.e. it must be the URN of one of the related chapters or segments), otherwise no switching will occur. Switching
 *  to the currently playing URN restarts playback at its beginning.
 *
 *  @param completionHandler The completion handler called once switching finishes. The block will only be called when
 *                           switching is performed, and with `finished` set to `YES` iff playback could successfully
 *                           resume afterwards.
 *
 *  @return `YES` iff switching occurred successfully.
 */
- (BOOL)switchToURN:(SRGMediaURN *)URN withCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

/**
 *  Switch to the specified subdivision, resuming playback if necessary. The subdivision must be related to the
 *  current playback context (i.e. it must be one of its related chapters or segments), otherwise no switching will occur.
 *  Switching to the currently playing subdivision restarts playback at its beginning.
 *
 *  @param The completion handler called once switching finishes. The block will only be called when switching is performed,
 *         and with `finished` set to `YES` iff playback could successfully resume afterwards.
 *
 *  @return `YES` iff switching occurred successfully.
 */
- (BOOL)switchToSubdivision:(SRGSubdivision *)subdivision withCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

/**
 *  Return the current data availability. KVO-observable.
 *
 *  @discussion The availability is reset to `SRGLetterboxDataAvailabilityNone` when calling a prepare / play methods
 *              to play new content.
 */
@property (nonatomic, readonly) SRGLetterboxDataAvailability dataAvailability;

/**
 *  Set to `YES` to mute the player. Default is `NO`.
 */
@property (nonatomic, getter=isMuted) BOOL muted;

/**
 *  Set to `YES` so that a retry automatically resumes playback (e.g. after a network loss, when the start time of
 *  a previously not available media has been reached, or when the content URL has changed). Default is `YES`. If 
 *  set to `NO`, playback will only be prepared, but playback will not actually start.
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
 *  Playlist support. Provide a data source supplying previous and next medias to be played.
 *
 *  @discussion Playlist controls are not available when picture in picture is active.
 */
@interface SRGLetterboxController (Playlists)

/**
 *  The playlist data source.
 */
@property (nonatomic, weak, nullable) id<SRGLetterboxControllerPlaylistDataSource> playlistDataSource;

/**
 *  Prepare to play the next media in the playlist. If you want playback to start right after preparation, call `-play`
 *  from the completion handler.
 *
 *  @param completionHandler The completion block to be called after the controller has finished preparing the media. This
 *                           block will only be called if the media could be successfully prepared.
 *
 *  @return
 *
 *  @discussion `YES` iff successful. Returns `NO` when picture in picture is active.
 */
- (BOOL)prepareToPlayNextMediaWithCompletionHandler:(nullable void (^)(void))completionHandler;

/**
 *  Same as `-prepareToPlayNextMediaWithCompletionHandler:`, but with the previous madia in the playlist.
 */
- (BOOL)prepareToPlayPreviousMediaWithCompletionHandler:(nullable void (^)(void))completionHandler;

/**
 *  Play the next media currently available from the playlist.
 *
 *  @discussion `YES` iff successful. Returns `NO` when picture in picture is active.
 *
 *  @discussion Not available when picture in picture is active.
 */
- (BOOL)playNextMedia;

/**
 *  Same as `-playNextMedia`, but with the previous media in the playlist.
 */
- (BOOL)playPreviousMedia;

/**
 *  The next media currently available from the playlist.
 */
@property (nonatomic, readonly, nullable) SRGMedia *nextMedia;

/**
 *  The previous media currently available from the playlist.
 */
@property (nonatomic, readonly, nullable) SRGMedia *previousMedia;

@end

/**
 *  Continuous playback support, i.e. automatically playing the next media in a playlist when a media playback ends.
 *  Requires a playlist data source supplying next item information.
 *
 *  Remark: Continuous playback is not enabled when picture in picture is active.
 */
@interface SRGLetterboxController (ContinuousPlayback)

/**
 *  The delay before playback automatically continues with the next media.
 *
 *  The default value is `SRGLetterboxContinuousPlaybackDelayDefault`. Use `SRGLetterboxContinuousPlaybackDelayDisabled` to
 *  disable continuous playback.
 *
 *  @discussion Values smaller than 0 will be fixed to 0.
 */
@property (nonatomic) NSTimeInterval continuousPlaybackDelay;

/**
 *  The date at which the continuous playback transition to the next media started. KVO-observable.
 *
 *  @discussion The start date is `nil` if there is no active transition.
 */
@property (nonatomic, readonly, nullable) NSDate *continuousPlaybackTransitionStartDate;

/**
 *  The date at which continuous playback will resume with the next media. KVO-observable.
 *
 *  @discussion The end date is `nil` if there no active transition. Once an end date has been determined,
 *              changing `continuousPlaybackDelay` will not alter it.
 */
@property (nonatomic, readonly, nullable) NSDate *continuousPlaybackTransitionEndDate;

/**
 *  The upcoming media while undergoing a continuous playback transition. KVO-observable.
 *
 *  @discussion The end date is `nil` if there no active transition. Once an end date has been determined,
 *              changing `continuousPlaybackDelay` will not alter it.
 */
@property (nonatomic, readonly, nullable) SRGMedia *continuousPlaybackUpcomingMedia;

/**
 *  While continuous playback is waiting for resumption, cancel automatic playback of the next item.
 *
 *  @dicussion This method has no effect when no resumption date has been determined.
 */
- (void)cancelContinuousPlayback;

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
        withChaptersOnly:(BOOL)chaptersOnly
       completionHandler:(nullable void (^)(void))completionHandler;

/**
 *  Prepare to play the specified media (Uniform Resource Name).
 *
 *  @discussion Does nothing if the media is the one currently being played. The best available quality is automatically
 *              played. The start bit rate is set to `SRGLetterboxDefaultStartBitRate`.
 */
- (void)prepareToPlayMedia:(SRGMedia *)media
          withChaptersOnly:(BOOL)chaptersOnly
         completionHandler:(nullable void (^)(void))completionHandler;

/**
 *  Play the specified URN (Uniform Resource Name).
 *
 *  For more information, @see `-prepareToPlayURN:withPreferredStreamType:quality:startBitRate:completionHandler:.
 *
 *  @discussion Does nothing if the media is the one currently being played.
 */
- (void)playURN:(SRGMediaURN *)URN withPreferredStreamType:(SRGStreamType)streamType quality:(SRGQuality)quality startBitRate:(NSInteger)startBitRate chaptersOnly:(BOOL)chaptersOnly;

/**
 *  Play the specified media.
 *
 *  For more information, @see `-prepareToPlayMedia:withPreferredStreamType:quality:startBitRate:completionHandler:.
 *
 *  @discussion Does nothing if the media is the one currently being played.
 */
- (void)playMedia:(SRGMedia *)media withPreferredStreamType:(SRGStreamType)streamType quality:(SRGQuality)quality startBitRate:(NSInteger)startBitRate chaptersOnly:(BOOL)chaptersOnly;

/**
 *  Play the specified URN (Uniform Resource Name).
 *
 *  @discussion Does nothing if the URN is the one currently being played. The best available stream type and quality
 *              are automatically used. The start bit rate is set to `SRGLetterboxDefaultStartBitRate`.
 */
- (void)playURN:(SRGMediaURN *)URN withChaptersOnly:(BOOL)chaptersOnly;

/**
 *  Play the specified media.
 *
 *  @discussion Does nothing if the URN is the one currently being played. The best available stream type and quality
 *              are automatically used. The start bit rate is set to `SRGLetterboxDefaultStartBitRate`.
 */
- (void)playMedia:(SRGMedia *)media withChaptersOnly:(BOOL)chaptersOnly;

/**
 *  Ask the controller to seek to a given location efficiently (the seek might be not perfeclty accurate but will be faster).
 *
 *  For more information, @see `-seekToTime:withToleranceBefore:toleranceAfter:completionHandler:`.
 */
- (void)seekEfficientlyToTime:(CMTime)time withCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

/**
 *  Ask the controller to seek to a given location with no tolerance (this might incur some decoding overhead).
 *
 *  For more information, @see `-seekToTime:withToleranceBefore:toleranceAfter:completionHandler:`.
 */
- (void)seekPreciselyToTime:(CMTime)time withCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

@end

/**
 *  Standard skips.
 */
@interface SRGLetterboxController (Skips)

/**
 *  Return `YES` iff the player can skip backward from `SRGLetterboxBackwardSkipInterval` seconds.
 */
- (BOOL)canSkipBackward;

/**
 *  Return `YES` iff the player can skip forward from `SRGLetterboxForwardSkipInterval` seconds.
 */
- (BOOL)canSkipForward;

/**
 *  Return `YES` iff the player can skip to live conditions.
 *
 *  @discussion Always returns `NO` for on-demand streams.
 */
- (BOOL)canSkipToLive;

/**
 *  Skip backward from a `SRGLetterboxBackwardSkipInterval` seconds.
 *
 *  @param completionHandler The completion handler called once skipping finishes. The block will only be called when
 *                           skipping is possible, and with `finished` set to `YES` iff skipping was not interrupted.
 *
 *  @return `YES` iff skipping is possible.
 */
- (BOOL)skipBackwardWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

/**
 *  Skip forward from a `SRGLetterboxForwardSkipInterval` seconds.
 *
 *  @param completionHandler The completion handler called once skipping finishes. The block will only be called when
 *                           skipping is possible, and with `finished` set to `YES` iff skipping was not interrupted.
 *
 *  @return `YES` iff skipping is possible.
 */
- (BOOL)skipForwardWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

/**
 *  Skip forward to live conditions.
 *
 *  @param completionHandler The completion handler called once skipping finishes. The block will only be called when
 *                           skipping is possible, and with `finished` set to `YES` iff skipping was not interrupted.
 *
 *  @return `YES` iff skipping is possible. Always returns `NO` for on-demand streams.
 */
- (BOOL)skipToLiveWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler;

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
 *  The current subdivision being played.
 */
@property (nonatomic, readonly, nullable) SRGSubdivision *subdivision;

/**
 *  The current subdivision (segment or chapter) being played, as an `SRGMedia` object.
 */
@property (nonatomic, readonly, nullable) SRGMedia *subdivisionMedia;

/**
 *  The current full-length information.
 */
@property (nonatomic, readonly, nullable) SRGMedia *fullLengthMedia;

/**
 *  The resource which is being played.
 */
@property (nonatomic, readonly, nullable) SRGResource *resource;

/**
 *  Error (if any has been encountered).
 */
@property (nonatomic, readonly, nullable) NSError *error;

@end

@interface SRGLetterboxController (ServerSettings)

/**
 *  The URL of the service data must be returned from. By default or if reset to `nil`, the production server is
 *  used. Official URL values can be found in `SRGDataProvider.h`.
 */
@property (nonatomic, null_resettable) NSURL *serviceURL;

/**
 *  Optional global headers which will added to all requests performed by the controller when retrieving data.
 */
@property (nonatomic, nullable) NSDictionary<NSString *, NSString *> *globalHeaders;

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
 *  Time interval for controller automatic updates.
 *
 *  Default is `SRGLetterboxUpdateIntervalDefault`, and minimum is 10 seconds.
 */
@property (nonatomic) NSTimeInterval updateInterval;

/**
 *  Time interval between channel information updates, notified by a `SRGLetterboxMetadataDidChangeNotification`
 *  notification.
 *
 *  Default is `SRGLetterboxChannelUpdateIntervalDefault`, and minimum is 10 seconds.
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
 *              door to several inconsistencies, most notably with segments).
 *
 *              The overridden URL should be of the same type as the original one (e.g. a livestream URL should
 *              only be overridden with another livestream URL), otherwise the behhavior is undefined.
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
