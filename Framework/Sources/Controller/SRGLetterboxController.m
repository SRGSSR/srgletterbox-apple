//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSTimer+SRGLetterbox.h"
#import "SRGLetterboxService+Private.h"
#import "SRGLetterboxError.h"
#import "SRGLetterboxLogger.h"

#import <FXReachability/FXReachability.h>
#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>
#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

const NSInteger SRGLetterboxDefaultStartBitRate = 800;

const NSInteger SRGLetterboxBackwardSkipInterval = 10.;
const NSInteger SRGLetterboxForwardSkipInterval = 30.;

NSString * const SRGLetterboxControllerPlaybackStateDidChangeNotification = @"SRGLetterboxControllerPlaybackStateDidChangeNotification";
NSString * const SRGLetterboxMetadataDidChangeNotification = @"SRGLetterboxMetadataDidChangeNotification";

NSString * const SRGLetterboxURNKey = @"SRGLetterboxURNKey";
NSString * const SRGLetterboxMediaKey = @"SRGLetterboxMediaKey";
NSString * const SRGLetterboxMediaCompositionKey = @"SRGLetterboxMediaCompositionKey";
NSString * const SRGLetterboxSubdivisionKey = @"SRGLetterboxSubdivisionKey";
NSString * const SRGLetterboxChannelKey = @"SRGLetterboxChannelKey";

NSString * const SRGLetterboxPreviousURNKey = @"SRGLetterboxPreviousURNKey";
NSString * const SRGLetterboxPreviousMediaKey = @"SRGLetterboxPreviousMediaKey";
NSString * const SRGLetterboxPreviousMediaCompositionKey = @"SRGLetterboxPreviousMediaCompositionKey";
NSString * const SRGLetterboxPreviousSubdivisionKey = @"SRGLetterboxPreviousSubdivisionKey";
NSString * const SRGLetterboxPreviousChannelKey = @"SRGLetterboxPreviousChannelKey";

NSString * const SRGLetterboxPlaybackDidFailNotification = @"SRGLetterboxPlaybackDidFailNotification";

NSString * const SRGLetterboxPlaybackDidRetryNotification = @"SRGLetterboxPlaybackDidRetryNotification";

NSString * const SRGLetterboxErrorKey = @"SRGLetterboxErrorKey";

static NSString *SRGDataProviderBusinessUnitIdentifierForVendor(SRGVendor vendor)
{
    static NSDictionary *s_businessUnitIdentifiers;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_businessUnitIdentifiers = @{ @(SRGVendorRSI) : SRGDataProviderBusinessUnitIdentifierRSI,
                                       @(SRGVendorRTR) : SRGDataProviderBusinessUnitIdentifierRTR,
                                       @(SRGVendorRTS) : SRGDataProviderBusinessUnitIdentifierRTS,
                                       @(SRGVendorSRF) : SRGDataProviderBusinessUnitIdentifierSRF,
                                       @(SRGVendorSWI) : SRGDataProviderBusinessUnitIdentifierSWI };
    });
    return s_businessUnitIdentifiers[@(vendor)];
}

static NSError *SRGBlockingReasonErrorForMediaComposition(SRGMediaComposition *mediaComposition)
{
    SRGChapter *mainChapter = mediaComposition.mainChapter;
    SRGMedia *media = [mediaComposition mediaForSubdivision:mainChapter];
    SRGBlockingReason blockingReason = mainChapter.blockingReason;
    
    // Observe start and end dates first. If we are offline, the date range information is more reliable blocking reasons,
    // if retrieved easlier, might be outdated.
    if (SRGDataProviderAvailabilityForMediaMetadata(media) == SRGMediaAvailabilityNotYetAvailable) {
        return [NSError errorWithDomain:SRGLetterboxErrorDomain
                                   code:SRGLetterboxErrorCodeNotAvailable
                               userInfo:@{ NSLocalizedDescriptionKey : SRGMessageForBlockedMediaWithBlockingReason(SRGBlockingReasonStartDate) }];
    }
    else if (SRGDataProviderAvailabilityForMediaMetadata(media) == SRGMediaAvailabilityNotAvailableAnymore) {
        return [NSError errorWithDomain:SRGLetterboxErrorDomain
                                   code:SRGLetterboxErrorCodeNotAvailable
                               userInfo:@{ NSLocalizedDescriptionKey : SRGMessageForBlockedMediaWithBlockingReason(SRGBlockingReasonEndDate) }];
    }
    // Date blocking has been dealt with more reliably above
    else if (blockingReason != SRGBlockingReasonNone && blockingReason != SRGBlockingReasonStartDate && blockingReason != SRGBlockingReasonEndDate) {
        return [NSError errorWithDomain:SRGLetterboxErrorDomain
                                   code:SRGLetterboxErrorCodeBlocked
                               userInfo:@{ NSLocalizedDescriptionKey : SRGMessageForBlockedMediaWithBlockingReason(blockingReason) }];
    }
    else {
        return nil;
    }
}

@interface SRGLetterboxController ()

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@property (nonatomic) SRGMediaURN *URN;
@property (nonatomic) SRGMedia *media;
@property (nonatomic) SRGMediaComposition *mediaComposition;
@property (nonatomic) SRGChannel *channel;
@property (nonatomic) SRGSubdivision *subdivision;
@property (nonatomic) SRGQuality quality;
@property (nonatomic) NSInteger startBitRate;
@property (nonatomic) BOOL chaptersOnly;
@property (nonatomic) NSError *error;

@property (nonatomic) SRGLetterboxDataAvailability dataAvailability;
@property (nonatomic) SRGMediaPlayerPlaybackState playbackState;

@property (nonatomic) SRGDataProvider *dataProvider;
@property (nonatomic) SRGRequestQueue *requestQueue;

// Use timers (not time observers) so that updates are performed also when the controller is idle
@property (nonatomic) NSTimer *streamAvailabilyCheckTimer;
@property (nonatomic) NSTimer *channelUpdateTimer;

// Timers for single metadata updates at start and end times
@property (nonatomic) NSTimer *startDateTimer;
@property (nonatomic) NSTimer *endDateTimer;

@property (nonatomic, copy) void (^playerConfigurationBlock)(AVPlayer *player);
@property (nonatomic, copy) SRGLetterboxURLOverridingBlock contentURLOverridingBlock;

@property (nonatomic) NSTimeInterval streamAvailabilityCheckInterval;
@property (nonatomic) NSTimeInterval channelUpdateInterval;

@property (nonatomic, getter=isTracked) BOOL tracked;

@end

@implementation SRGLetterboxController

@synthesize serviceURL = _serviceURL;

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.mediaPlayerController = [[SRGMediaPlayerController alloc] init];
        
        @weakify(self)
        self.mediaPlayerController.playerConfigurationBlock = ^(AVPlayer *player) {
            @strongify(self)
            
            // Do not allow Airplay video playback by default
            player.allowsExternalPlayback = NO;
            
            // Only update the audio session if needed to avoid audio hiccups
            NSString *mode = (self.media.mediaType == SRGMediaTypeVideo) ? AVAudioSessionModeMoviePlayback : AVAudioSessionModeDefault;
            if (! [[AVAudioSession sharedInstance].mode isEqualToString:mode]) {
                [[AVAudioSession sharedInstance] setMode:mode error:NULL];
            }
            
            // Call the configuration block afterwards (so that the above default behavior can be overridden)
            self.playerConfigurationBlock ? self.playerConfigurationBlock(player) : nil;
            player.muted = self.muted;
        };
        
        // Also register the associated periodic time observers
        self.streamAvailabilityCheckInterval = 5. * 60.;
        self.channelUpdateInterval = 30.;
        
        // Observe playback state changes
        [self addObserver:self keyPath:@keypath(self.mediaPlayerController.playbackState) options:NSKeyValueObservingOptionNew block:^(MAKVONotification *notification) {
            @strongify(self)
            self.playbackState = [notification.newValue integerValue];
        }];
        _playbackState = self.mediaPlayerController.playbackState;          // No setter used on purpose to set the initial value. The setter will notify changes
        
        self.resumesAfterRetry = YES;
        self.resumesAfterRouteBecomesUnavailable = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityDidChange:)
                                                     name:FXReachabilityStatusDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateDidChange:)
                                                     name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                   object:self.mediaPlayerController];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(segmentDidStart:)
                                                     name:SRGMediaPlayerSegmentDidStartNotification
                                                   object:self.mediaPlayerController];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(segmentDidEnd:)
                                                     name:SRGMediaPlayerSegmentDidEndNotification
                                                   object:self.mediaPlayerController];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackDidFail:)
                                                     name:SRGMediaPlayerPlaybackDidFailNotification
                                                   object:self.mediaPlayerController];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(routeDidChange:)
                                                     name:AVAudioSessionRouteChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    // Invalidate timers
    self.streamAvailabilyCheckTimer = nil;
    self.channelUpdateTimer = nil;
    self.startDateTimer = nil;
    self.endDateTimer = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Getters and setters

- (void)setPlaybackState:(SRGMediaPlayerPlaybackState)playbackState
{
    if (_playbackState == playbackState) {
        return;
    }
    
    NSDictionary *userInfo = @{ SRGMediaPlayerPlaybackStateKey : @(playbackState),
                                SRGMediaPlayerPreviousPlaybackStateKey: @(_playbackState) };
    
    [self willChangeValueForKey:@keypath(self.playbackState)];
    _playbackState = playbackState;
    [self didChangeValueForKey:@keypath(self.playbackState)];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxControllerPlaybackStateDidChangeNotification
                                                        object:self
                                                      userInfo:userInfo];
}

- (BOOL)isLive
{
    return self.mediaPlayerController.live;
}

- (CMTime)currentTime
{
    return self.mediaPlayerController.player.currentTime;
}

- (NSDate *)date
{
    return self.mediaPlayerController.date;
}

- (CMTimeRange)timeRange
{
    return self.mediaPlayerController.timeRange;
}

- (void)setMuted:(BOOL)muted
{
    _muted = muted;
    [self.mediaPlayerController reloadPlayerConfiguration];
}

- (BOOL)areBackgroundServicesEnabled
{
    return self == [SRGLetterboxService sharedService].controller;
}

- (BOOL)isPictureInPictureEnabled
{
    return self.backgroundServicesEnabled && [SRGLetterboxService sharedService].pictureInPictureDelegate;
}

- (BOOL)isPictureInPictureActive
{
    return self.pictureInPictureEnabled && self.mediaPlayerController.pictureInPictureController.pictureInPictureActive;
}

- (void)setServiceURL:(NSURL *)serviceURL
{
    _serviceURL = serviceURL;
}

- (NSURL *)serviceURL
{
    return _serviceURL ?: SRGIntegrationLayerProductionServiceURL();
}

- (void)setTracked:(BOOL)tracked
{
    self.mediaPlayerController.tracked = tracked;
}

- (BOOL)isTracked
{
    return self.mediaPlayerController.tracked;
}

- (void)setStreamAvailabilityCheckInterval:(NSTimeInterval)streamAvailabilityCheckInterval
{
    if (streamAvailabilityCheckInterval < 10.) {
        SRGLetterboxLogWarning(@"controller", @"The mimimum stream availability check interval is 10 seconds. Fixed to 10 seconds.");
        streamAvailabilityCheckInterval = 10.;
    }
    
    _streamAvailabilityCheckInterval = streamAvailabilityCheckInterval;
    
    @weakify(self)
    self.streamAvailabilyCheckTimer = [NSTimer srg_scheduledTimerWithTimeInterval:streamAvailabilityCheckInterval repeats:YES block:^(NSTimer * _Nonnull timer) {
        @strongify(self)
        [self updateMetadataWithCompletionBlock:^(NSError *error, BOOL URLChanged) {
            if (URLChanged) {
                SRGMediaPlayerPlaybackState playbackState = self.mediaPlayerController.playbackState;
                if (playbackState != SRGMediaPlayerPlaybackStateIdle && playbackState != SRGMediaPlayerPlaybackStateEnded) {
                    [self restart];
                }
                else {
                    [self stop];
                }
            }
            else if (error) {
                [self reportError:error];
                [self stop];
            }
        }];
    }];
}

- (void)setChannelUpdateInterval:(NSTimeInterval)channelUpdateInterval
{
    if (channelUpdateInterval < 10.) {
        SRGLetterboxLogWarning(@"controller", @"The mimimum now and next update interval is 10 seconds. Fixed to 10 seconds.");
        channelUpdateInterval = 10.;
    }
    
    @weakify(self)
    self.channelUpdateTimer = [NSTimer srg_scheduledTimerWithTimeInterval:channelUpdateInterval repeats:YES block:^(NSTimer * _Nonnull timer) {
       @strongify(self)
        
        [self updateChannel];
    }];
}

- (SRGMedia *)fullLengthMedia
{
    return self.mediaComposition.fullLengthMedia;
}

- (SRGMedia *)subdivisionMedia
{
    return [self.mediaComposition mediaForSubdivision:self.subdivision];
}

- (BOOL)isContentURLOverridden
{
    if (! self.URN) {
        return NO;
    }
    
    return self.contentURLOverridingBlock && self.contentURLOverridingBlock(self.URN);
}

- (void)setStreamAvailabilyCheckTimer:(NSTimer *)streamAvailabilyCheckTimer
{
    [_streamAvailabilyCheckTimer invalidate];
    _streamAvailabilyCheckTimer = streamAvailabilyCheckTimer;
}

- (void)setChannelUpdateTimer:(NSTimer *)channelUpdateTimer
{
    [_channelUpdateTimer invalidate];
    _channelUpdateTimer = channelUpdateTimer;
}

- (void)setStartDateTimer:(NSTimer *)startDateTimer
{
    [_startDateTimer invalidate];
    _startDateTimer = startDateTimer;
}

- (void)setEndDateTimer:(NSTimer *)endDateTimer
{
    [_endDateTimer invalidate];
    _endDateTimer = endDateTimer;
}

#pragma mark Periodic time observers

- (id)addPeriodicTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(CMTime))block
{
    return [self.mediaPlayerController addPeriodicTimeObserverForInterval:interval queue:queue usingBlock:block];
}

- (void)removePeriodicTimeObserver:(id)observer
{
    [self.mediaPlayerController removePeriodicTimeObserver:observer];
}

#pragma mark Data

// Pass in which data is available, the method will ensure that the data is consistent based on the most comprehensive
// information available (media composition first, then media, finally URN). Less comprehensive data will be ignored
- (void)updateWithURN:(SRGMediaURN *)URN media:(SRGMedia *)media mediaComposition:(SRGMediaComposition *)mediaComposition subdivision:(SRGSubdivision *)subdivision channel:(SRGChannel *)channel
{
    if (mediaComposition) {
        media = [mediaComposition mediaForSubdivision:mediaComposition.mainSegment ?: mediaComposition.mainChapter];
    }
    
    if (media) {
        URN = media.URN;
    }
    
    // We do not check that the data actually changed. The reason is that object comparison is shallow and only checks
    // object identity (e.g. medias are compared by URN). Checking objects for equality here would not take into account
    // data changes, which might occur in rare cases. Sending a few additional notifications, even when no real change
    // occurred, is harmless, though.
    
    SRGMediaURN *previousURN = self.URN;
    SRGMedia *previousMedia = self.media;
    SRGMediaComposition *previousMediaComposition = self.mediaComposition;
    SRGSubdivision *previousSubdivision = self.subdivision;
    SRGChannel *previousChannel = self.channel;
    
    self.URN = URN;
    self.media = media;
    self.mediaComposition = mediaComposition;
    self.subdivision = subdivision ?: self.mediaComposition.mainChapter;
    self.channel = channel ?: media.channel;
    
    NSMutableDictionary<NSString *, id> *userInfo = [NSMutableDictionary dictionary];
    if (URN) {
        userInfo[SRGLetterboxURNKey] = URN;
    }
    if (media) {
        userInfo[SRGLetterboxMediaKey] = media;
    }
    if (mediaComposition) {
        userInfo[SRGLetterboxMediaCompositionKey] = mediaComposition;
    }
    if (subdivision) {
        userInfo[SRGLetterboxSubdivisionKey] = subdivision;
    }
    if (channel) {
        userInfo[SRGLetterboxChannelKey] = channel;
    }
    if (previousURN) {
        userInfo[SRGLetterboxPreviousURNKey] = previousURN;
    }
    if (previousMedia) {
        userInfo[SRGLetterboxPreviousMediaKey] = previousMedia;
    }
    if (previousMediaComposition) {
        userInfo[SRGLetterboxPreviousMediaCompositionKey] = previousMediaComposition;
    }
    if (previousSubdivision) {
        userInfo[SRGLetterboxPreviousSubdivisionKey] = previousSubdivision;
    }
    if (previousChannel) {
        userInfo[SRGLetterboxPreviousChannelKey] = previousChannel;
    }
    
    NSTimeInterval startTimeInterval = [media.startDate timeIntervalSinceNow];
    if (startTimeInterval > 0.) {
        @weakify(self)
        self.startDateTimer = [NSTimer srg_scheduledTimerWithTimeInterval:startTimeInterval repeats:NO block:^(NSTimer * _Nonnull timer) {
            @strongify(self)
            [self updateMetadataWithCompletionBlock:^(NSError *error, BOOL URLChanged) {
                if (error) {
                    [self reportError:error];
                    [self stop];
                }
                else {
                    [self playMedia:self.media withPreferredQuality:self.quality startBitRate:self.startBitRate chaptersOnly:self.chaptersOnly];
                }
            }];
        }];
    }
    else {
        self.startDateTimer = nil;
    }
    
    NSTimeInterval endTimeInterval = [media.endDate timeIntervalSinceNow];
    if (endTimeInterval > 0.) {
        @weakify(self)
        self.endDateTimer = [NSTimer srg_scheduledTimerWithTimeInterval:endTimeInterval repeats:NO block:^(NSTimer * _Nonnull timer) {
            @strongify(self)
            [self updateMetadataWithCompletionBlock:^(NSError *error, BOOL URLChanged) {
                [self reportError:error];
                [self stop];
            }];
        }];
    }
    else {
        self.endDateTimer = nil;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxMetadataDidChangeNotification object:self userInfo:[userInfo copy]];
}

- (void)updateMetadataWithCompletionBlock:(void (^)(NSError *error, BOOL URLChanged))completionBlock
{
    NSParameterAssert(completionBlock);
    
    if (self.contentURLOverridden) {
        completionBlock(nil, NO);
        return;
    }
    
    [[self.dataProvider mediaCompositionWithURN:self.URN chaptersOnly:self.chaptersOnly completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        SRGMediaComposition *currentMediaComposition = self.mediaComposition;
        
        // Update metadata if retrieved, otherwise perform a check with the metadata we already have
        if (mediaComposition) {
            [self updateWithURN:nil media:nil mediaComposition:mediaComposition subdivision:self.subdivision channel:self.channel];
        }
        else {
            mediaComposition = self.mediaComposition;
        }
        
        if (mediaComposition) {
            // Check whether the media is now blocked (conditions might have changed, e.g. user location or time)
            NSError *blockingReasonError = SRGBlockingReasonErrorForMediaComposition(mediaComposition);
            if (blockingReasonError) {
                completionBlock(blockingReasonError, NO);
                return;
            }
            
            // Update the URL if resources change (also cover DVR to live change or conversely, aka DVR "kill switch")
            NSSet<SRGResource *> *currentResources = [NSSet setWithArray:currentMediaComposition.mainChapter.playableResources];
            NSSet<SRGResource *> *fetchedResources = [NSSet setWithArray:mediaComposition.mainChapter.playableResources];
            if (! [currentResources isEqualToSet:fetchedResources]) {
                completionBlock(nil, YES);
                return;
            }
        }
        
        completionBlock(nil, NO);
    }] resume];
}

- (void)updateChannel
{
    // Only for livestreams with a channel uid
    if (self.media.contentType != SRGContentTypeLivestream || ! self.media.channel.uid) {
        return;
    }
    
    void (^completionBlock)(SRGChannel * _Nullable, NSError * _Nullable) = ^(SRGChannel * _Nullable channel, NSError * _Nullable error) {
        [self updateWithURN:self.URN media:self.media mediaComposition:self.mediaComposition subdivision:self.subdivision channel:channel];
    };
    
    if (self.media.mediaType == SRGMediaTypeVideo) {
        [[self.dataProvider tvChannelWithUid:self.media.channel.uid completionBlock:completionBlock] resume];
    }
    else if (self.media.mediaType == SRGMediaTypeAudio) {
        if (self.media.vendor == SRGVendorSRF && ! [self.media.uid isEqualToString:self.media.channel.uid]) {
            [[self.dataProvider radioChannelWithUid:self.media.channel.uid livestreamUid:self.media.uid completionBlock:completionBlock] resume];
        }
        else {
            [[self.dataProvider radioChannelWithUid:self.media.channel.uid livestreamUid:nil completionBlock:completionBlock] resume];
        }
    }
}

#pragma mark Playback

- (void)prepareToPlayURN:(SRGMediaURN *)URN withPreferredQuality:(SRGQuality)quality startBitRate:(NSInteger)startBitRate chaptersOnly:(BOOL)chaptersOnly completionHandler:(void (^)(void))completionHandler
{
    [self prepareToPlayURN:URN media:nil withPreferredQuality:quality startBitRate:startBitRate chaptersOnly:chaptersOnly completionHandler:completionHandler];
}

- (void)prepareToPlayMedia:(SRGMedia *)media withPreferredQuality:(SRGQuality)quality startBitRate:(NSInteger)startBitRate chaptersOnly:(BOOL)chaptersOnly completionHandler:(void (^)(void))completionHandler
{
    [self prepareToPlayURN:nil media:media withPreferredQuality:quality startBitRate:startBitRate chaptersOnly:chaptersOnly completionHandler:completionHandler];
}

- (void)prepareToPlayURN:(SRGMediaURN *)URN media:(SRGMedia *)media withPreferredQuality:(SRGQuality)quality startBitRate:(NSInteger)startBitRate chaptersOnly:(BOOL)chaptersOnly completionHandler:(void (^)(void))completionHandler
{
    if (media) {
        URN = media.URN;
    }
    
    if (! URN) {
        return;
    }
    
    if (startBitRate < 0) {
        startBitRate = 0;
    }
    
    // If already playing the media, does nothing
    if (self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateIdle && [self.media.URN isEqual:URN]) {
        return;
    }
    
    [self resetWithURN:URN media:media];
    
    // Save the settings for restarting after connection loss
    self.quality = quality;
    self.startBitRate = startBitRate;
    self.chaptersOnly = chaptersOnly;
    
    @weakify(self)
    self.requestQueue = [[SRGRequestQueue alloc] initWithStateChangeBlock:^(BOOL finished, NSError * _Nullable error) {
        @strongify(self)
        
        if (finished) {
            if (! error) {
                self.dataAvailability = SRGLetterboxDataAvailabilityLoaded;
            }
            else {
                if (self.dataAvailability == SRGLetterboxDataAvailabilityLoading) {
                    self.dataAvailability = SRGLetterboxDataAvailabilityNone;
                }
                [self reportError:error];
            }
        }
    }];
    
    self.dataAvailability = SRGLetterboxDataAvailabilityLoading;
    
    // Apply overriding if available. Overriding requires a media to be available. No media composition is retrieved
    if (self.contentURLOverridingBlock) {
        NSURL *contentURL = self.contentURLOverridingBlock(URN);
        if (contentURL) {
            // Media readily available. Done
            if (media) {
                self.dataAvailability = SRGLetterboxDataAvailabilityLoaded;
                [self.mediaPlayerController playURL:contentURL];
            }
            // Retrieve the media
            else {
                void (^mediasCompletionBlock)(NSArray<SRGMedia *> * _Nullable, NSError * _Nullable) = ^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
                    if (error) {
                        [self.requestQueue reportError:error];
                        return;
                    }
                    
                    [self updateWithURN:nil media:medias.firstObject mediaComposition:nil subdivision:nil channel:nil];
                    [self.mediaPlayerController playURL:contentURL];
                };
                
                if (URN.mediaType == SRGMediaTypeVideo) {
                    SRGRequest *mediaRequest = [self.dataProvider videosWithUids:@[URN.uid] completionBlock:mediasCompletionBlock];
                    [self.requestQueue addRequest:mediaRequest resume:YES];
                }
                else {
                    SRGRequest *mediaRequest = [self.dataProvider audiosWithUids:@[URN.uid] completionBlock:mediasCompletionBlock];
                    [self.requestQueue addRequest:mediaRequest resume:YES];
                }
            }
            return;
        }
    }
    
    SRGRequest *mediaCompositionRequest = [self.dataProvider mediaCompositionWithURN:self.URN chaptersOnly:chaptersOnly completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        @strongify(self)
        
        if (error) {
            [self.requestQueue reportError:error];
            return;
        }
        
        [self updateWithURN:nil media:nil mediaComposition:mediaComposition subdivision:mediaComposition.mainSegment channel:nil];
        [self updateChannel];
        
        // Do not go further if the content is blocked
        NSError *blockingReasonError = SRGBlockingReasonErrorForMediaComposition(mediaComposition);
        if (blockingReasonError) {
            [self.requestQueue reportError:blockingReasonError];
            return;
        }
        
        @weakify(self)
        SRGRequest *playRequest = [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone quality:quality startBitRate:startBitRate userInfo:nil resume:NO completionHandler:^(NSError * _Nonnull error) {
            @strongify(self)
            
            if (error) {
                [self.requestQueue reportError:error];
                return;
            }
            
            completionHandler ? completionHandler() : nil;
        }];
        
        if (playRequest) {
            [self.requestQueue addRequest:playRequest resume:YES];
        }
        else {
            NSError *error = [NSError errorWithDomain:SRGLetterboxErrorDomain
                                                 code:SRGLetterboxErrorCodeNotFound
                                             userInfo:@{ NSLocalizedDescriptionKey : SRGLetterboxLocalizedString(@"The media cannot be played", @"Message displayed when a media cannot be played for some reason (the user should not know about)") }];
            [self.requestQueue reportError:error];
        }
    }];
    [self.requestQueue addRequest:mediaCompositionRequest resume:YES];
}

- (BOOL)switchToSubdivision:(SRGSubdivision *)subdivision
{
    if (! self.mediaComposition) {
        SRGLetterboxLogInfo(@"controller", @"No original media composition information is available. Cannot switch to another subdivision");
        return NO;
    }
    
    // Build the media composition for the provided subdivision
    SRGMediaComposition *mediaComposition = [self.mediaComposition mediaCompositionForSubdivision:subdivision];
    if (! mediaComposition) {
        SRGLetterboxLogInfo(@"controller", @"No subdivision media composition information is available. Cannot switch to another subdivision");
        return NO;
    }
    
    [self updateWithURN:nil media:nil mediaComposition:mediaComposition subdivision:subdivision channel:nil];
    
    // If playing another media or if the player is not playing, restart
    if ([subdivision isKindOfClass:[SRGChapter class]]
            || self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle
            || self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        SRGRequest *request = [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone quality:self.quality startBitRate:self.startBitRate userInfo:nil resume:NO completionHandler:nil];
        [self.requestQueue addRequest:request resume:YES];
    }
    // Playing another segment from the same media. Seek
    else {
        [self.mediaPlayerController seekToSegment:subdivision withCompletionHandler:^(BOOL finished) {
            [self.mediaPlayerController play];
        }];
    }
    
    return YES;
}

- (void)play
{
    [self.mediaPlayerController play];
}

- (void)pause
{
    [self.mediaPlayerController pause];
}

- (void)togglePlayPause
{
    [self.mediaPlayerController togglePlayPause];
}

- (void)stop
{
    [self.mediaPlayerController reset];
}

- (void)retry
{
    void (^prepareToPlayCompletionHandler)(void) = ^{
        if (self.resumesAfterRetry) {
            [self play];
        }
    };
    
    // Reuse the media if available (so that the information already available to clients is not reduced)
    if (self.media) {
        [self prepareToPlayMedia:self.media withPreferredQuality:self.quality startBitRate:self.startBitRate chaptersOnly:self.chaptersOnly completionHandler:prepareToPlayCompletionHandler];
    }
    else if (self.URN) {
        [self prepareToPlayURN:self.URN withPreferredQuality:self.quality startBitRate:self.startBitRate chaptersOnly:self.chaptersOnly completionHandler:prepareToPlayCompletionHandler];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxPlaybackDidRetryNotification object:self];
}

- (void)restart
{
    [self stop];
    [self retry];
}

- (void)reset
{
    [self resetWithURN:nil media:nil];
}

- (void)resetWithURN:(SRGMediaURN *)URN media:(SRGMedia *)media
{
    if (URN) {
        self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:self.serviceURL
                                                 businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierForVendor(URN.vendor)];
    }
    else {
        self.dataProvider = nil;
    }
    
    [self.mediaPlayerController reset];
    [self.requestQueue cancel];
    
    self.error = nil;
    
    self.dataAvailability = SRGLetterboxDataAvailabilityNone;
    
    self.quality = SRGQualityNone;
    self.startBitRate = 0;
    
    // Update metadata first so that it is current when the player status is changed below
    [self updateWithURN:URN media:media mediaComposition:nil subdivision:nil channel:nil];
}

- (void)seekToTime:(CMTime)time withToleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter completionHandler:(void (^)(BOOL))completionHandler
{
    [self.mediaPlayerController seekToTime:time withToleranceBefore:toleranceBefore toleranceAfter:toleranceAfter completionHandler:completionHandler];
}

- (void)reportError:(NSError *)error
{
    if (! error) {
        return;
    }
    
    // Forward Letterbox friendly errors
    if ([error.domain isEqualToString:SRGLetterboxErrorDomain]) {
        self.error = error;
    }
    // Use a friendly error message for network errors (might be a connection loss, incorrect proxy settings, etc.)
    else if ([error.domain isEqualToString:(NSString *)kCFErrorDomainCFNetwork] || [error.domain isEqualToString:NSURLErrorDomain]) {
        self.error = [NSError errorWithDomain:SRGLetterboxErrorDomain
                                         code:SRGLetterboxErrorCodeNetwork
                                     userInfo:@{ NSLocalizedDescriptionKey : SRGLetterboxLocalizedString(@"A network issue has been encountered. Please check your Internet connection and network settings", @"Message displayed when a network error has been encountered"),
                                                 NSUnderlyingErrorKey : error }];
    }
    // Use a friendly error message for all other reasons
    else {
        self.error = [NSError errorWithDomain:SRGLetterboxErrorDomain
                                         code:SRGLetterboxErrorCodeNotPlayable
                                     userInfo:@{ NSLocalizedDescriptionKey : SRGLetterboxLocalizedString(@"The media cannot be played", @"Message displayed when a media cannot be played for some reason (the user should not know about)"),
                                                 NSUnderlyingErrorKey : error }];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxPlaybackDidFailNotification object:self userInfo:@{ SRGLetterboxErrorKey : self.error }];
}

#pragma mark Playback (convenience)

- (void)prepareToPlayURN:(SRGMediaURN *)URN withChaptersOnly:(BOOL)chaptersOnly completionHandler:(void (^)(void))completionHandler
{
    [self prepareToPlayURN:URN withPreferredQuality:SRGQualityNone startBitRate:SRGLetterboxDefaultStartBitRate chaptersOnly:chaptersOnly completionHandler:completionHandler];
}

- (void)prepareToPlayMedia:(SRGMedia *)media withChaptersOnly:(BOOL)chaptersOnly completionHandler:(void (^)(void))completionHandler
{
    [self prepareToPlayMedia:media withPreferredQuality:SRGQualityNone startBitRate:SRGLetterboxDefaultStartBitRate chaptersOnly:chaptersOnly completionHandler:completionHandler];
}

- (void)playURN:(SRGMediaURN *)URN withPreferredQuality:(SRGQuality)quality startBitRate:(NSInteger)startBitRate chaptersOnly:(BOOL)chaptersOnly
{
    @weakify(self)
    [self prepareToPlayURN:URN withPreferredQuality:quality startBitRate:startBitRate chaptersOnly:chaptersOnly completionHandler:^{
        @strongify(self)
        
        [self play];
    }];
}

- (void)playMedia:(SRGMedia *)media withPreferredQuality:(SRGQuality)quality startBitRate:(NSInteger)startBitRate chaptersOnly:(BOOL)chaptersOnly
{
    @weakify(self)
    [self prepareToPlayMedia:media withPreferredQuality:quality startBitRate:startBitRate chaptersOnly:chaptersOnly completionHandler:^{
        @strongify(self)
        
        [self play];
    }];
}

- (void)playURN:(SRGMediaURN *)URN withChaptersOnly:(BOOL)chaptersOnly
{
    [self playURN:URN withPreferredQuality:SRGQualityNone startBitRate:SRGLetterboxDefaultStartBitRate chaptersOnly:chaptersOnly];
}

- (void)playMedia:(SRGMedia *)media withChaptersOnly:(BOOL)chaptersOnly
{
    [self playMedia:media withPreferredQuality:SRGQualityNone startBitRate:SRGLetterboxDefaultStartBitRate chaptersOnly:chaptersOnly];
}

- (void)seekEfficientlyToTime:(CMTime)time withCompletionHandler:(void (^)(BOOL))completionHandler
{
    [self seekToTime:time withToleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity completionHandler:completionHandler];
}

- (void)seekPreciselyToTime:(CMTime)time withCompletionHandler:(void (^)(BOOL))completionHandler
{
    [self seekToTime:time withToleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:completionHandler];
}

#pragma mark Standard seeks

- (BOOL)canSkipBackward
{
    return [self canSkipBackwardFromTime:[self seekStartTime]];
}

- (BOOL)canSkipForward
{
    return [self canSkipForwardFromTime:[self seekStartTime]];
}

- (BOOL)canSkipToLive
{
    return self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR && [self canSkipForward];
}

- (void)skipBackwardWithCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    [self seekBackwardFromTime:[self seekStartTime] withCompletionHandler:completionHandler];
}

- (void)skipForwardWithCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    [self seekForwardFromTime:[self seekStartTime] withCompletionHandler:completionHandler];
}

#pragma mark Helpers

- (CMTime)seekStartTime
{
    return CMTIME_IS_INDEFINITE(self.mediaPlayerController.seekTargetTime) ? self.mediaPlayerController.player.currentTime : self.mediaPlayerController.seekTargetTime;
}

- (BOOL)canSkipBackwardFromTime:(CMTime)time
{
    if (CMTIME_IS_INDEFINITE(time)) {
        return NO;
    }
    
    SRGMediaPlayerStreamType streamType = self.mediaPlayerController.streamType;
    return (streamType == SRGMediaPlayerStreamTypeOnDemand || streamType == SRGMediaPlayerStreamTypeDVR);
}

- (BOOL)canSkipForwardFromTime:(CMTime)time
{
    if (CMTIME_IS_INDEFINITE(time)) {
        return NO;
    }
    
    SRGMediaPlayerController *mediaPlayerController = self.mediaPlayerController;
    return (mediaPlayerController.streamType == SRGMediaPlayerStreamTypeOnDemand && CMTimeGetSeconds(time) + SRGLetterboxForwardSkipInterval < CMTimeGetSeconds(mediaPlayerController.player.currentItem.duration))
        || (mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR && ! mediaPlayerController.live);
}

- (void)seekBackwardFromTime:(CMTime)time withCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    if (![self canSkipBackwardFromTime:time]) {
        completionHandler ? completionHandler(NO) : nil;
        return;
    }
    
    CMTime targetTime = CMTimeSubtract(time, CMTimeMakeWithSeconds(SRGLetterboxBackwardSkipInterval, NSEC_PER_SEC));
    [self seekToTime:targetTime withToleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity completionHandler:^(BOOL finished) {
        if (finished) {
            [self.mediaPlayerController play];
        }
        completionHandler ? completionHandler(finished) : nil;
    }];
}

- (void)seekForwardFromTime:(CMTime)time withCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    if (![self canSkipForwardFromTime:time]) {
        completionHandler ? completionHandler(NO) : nil;
        return;
    }
    
    CMTime targetTime = CMTimeAdd(time, CMTimeMakeWithSeconds(SRGLetterboxForwardSkipInterval, NSEC_PER_SEC));
    [self seekToTime:targetTime withToleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity completionHandler:^(BOOL finished) {
        if (finished) {
            [self.mediaPlayerController play];
        }
        completionHandler ? completionHandler(finished) : nil;
    }];
}

- (void)skipToLiveWithCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR) {
        [self seekToTime:CMTimeRangeGetEnd(self.mediaPlayerController.timeRange) withToleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity completionHandler:^(BOOL finished) {
            if (finished) {
                [self.mediaPlayerController play];
            }
            completionHandler ? completionHandler(finished) : nil;
        }];
    }
    else {
        completionHandler ? completionHandler(NO) : nil;
    }
}

- (void)reloadPlayerConfiguration
{
    [self.mediaPlayerController reloadPlayerConfiguration];
}

#pragma mark Notifications

- (void)reachabilityDidChange:(NSNotification *)notification
{
    if ([FXReachability sharedInstance].reachable) {
        [self retry];
    }
}

- (void)playbackStateDidChange:(NSNotification *)notification
{
    SRGMediaPlayerPlaybackState playbackState = [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue];
    
    // Do not let pause live streams, stop playback
    if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeLive && playbackState == SRGMediaPlayerPlaybackStatePaused) {
        [self.mediaPlayerController stop];
    }
}

- (void)segmentDidStart:(NSNotification *)notification
{
    SRGSubdivision *subdivision = notification.userInfo[SRGMediaPlayerSegmentKey];
    [self updateWithURN:self.URN media:self.media mediaComposition:self.mediaComposition subdivision:subdivision channel:self.channel];
}

- (void)segmentDidEnd:(NSNotification *)notification
{
    [self updateWithURN:self.URN media:self.media mediaComposition:self.mediaComposition subdivision:nil channel:self.channel];
}

- (void)playbackDidFail:(NSNotification *)notification
{
    [self reportError:notification.userInfo[SRGMediaPlayerErrorKey]];
}

- (void)routeDidChange:(NSNotification *)notification
{
    NSInteger routeChangeReason = [notification.userInfo[AVAudioSessionRouteChangeReasonKey] integerValue];
    if (routeChangeReason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable
            && self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying) {
        // Playback is automatically paused by the system. Force resume if desired. Wait a little bit (0.1 is an
        // empirical value), the system induced state change occurs slightly after this notification is received.
        // We could probably do something more robust (e.g. wait until the real state change), but this would lead
        // to additional complexity or states which do not seem required for correct behavior. Improve later if needed.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.resumesAfterRouteBecomesUnavailable) {
                [self play];
            }
        });
    }
}

#pragma mark KVO

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    if ([key isEqualToString:@keypath(SRGLetterboxController.new, playbackState)]) {
        return NO;
    }
    else {
        return [super automaticallyNotifiesObserversForKey:key];
    }
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; URN: %@; media: %@; mediaComposition: %@; channel: %@; error: %@; mediaPlayerController: %@>",
            [self class],
            self,
            self.URN,
            self.media,
            self.mediaComposition,
            self.channel,
            self.error,
            self.mediaPlayerController];
}

@end
