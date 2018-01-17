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
#import "SRGMediaComposition+SRGLetterbox.h"

#import <FXReachability/FXReachability.h>
#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>
#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

const NSInteger SRGLetterboxDefaultStartBitRate = 800;

const NSInteger SRGLetterboxBackwardSkipInterval = 10.;
const NSInteger SRGLetterboxForwardSkipInterval = 30.;

NSString * const SRGLetterboxPlaybackStateDidChangeNotification = @"SRGLetterboxPlaybackStateDidChangeNotification";
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

NSString * const SRGLetterboxLivestreamDidFinishNotification = @"SRGLetterboxLivestreamDidFinishNotification";

NSString * const SRGLetterboxSocialCountViewWillIncreaseNotification = @"SRGLetterboxSocialCountViewWillIncreaseNotification";

NSString * const SRGLetterboxErrorKey = @"SRGLetterboxErrorKey";

NSTimeInterval const SRGLetterboxUpdateIntervalDefault = 30.;
NSTimeInterval const SRGLetterboxChannelUpdateIntervalDefault = 30.;

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

static NSError *SRGBlockingReasonErrorForMedia(SRGMedia *media, NSDate *date)
{
    SRGBlockingReason blockingReason = [media blockingReasonAtDate:date];
    if (blockingReason == SRGBlockingReasonStartDate || blockingReason == SRGBlockingReasonEndDate) {
        return [NSError errorWithDomain:SRGLetterboxErrorDomain
                                   code:SRGLetterboxErrorCodeNotAvailable
                               userInfo:@{ NSLocalizedDescriptionKey : SRGMessageForBlockedMediaWithBlockingReason(blockingReason),
                                           SRGLetterboxBlockingReasonKey : @(blockingReason),
                                           SRGLetterboxTimeAvailabilityKey : @([media timeAvailabilityAtDate:date]) }];
    }
    else if (blockingReason != SRGBlockingReasonNone) {
        return [NSError errorWithDomain:SRGLetterboxErrorDomain
                                   code:SRGLetterboxErrorCodeBlocked
                               userInfo:@{ NSLocalizedDescriptionKey : SRGMessageForBlockedMediaWithBlockingReason(blockingReason),
                                           SRGLetterboxBlockingReasonKey : @(blockingReason) }];
    }
    else {
        return nil;
    }
}

@interface SRGLetterboxController ()

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@property (nonatomic) NSDictionary<NSString *, NSString *> *globalHeaders;

@property (nonatomic) SRGMediaURN *URN;
@property (nonatomic) SRGMedia *media;
@property (nonatomic) SRGMediaComposition *mediaComposition;
@property (nonatomic) SRGChannel *channel;
@property (nonatomic) SRGSubdivision *subdivision;
@property (nonatomic) SRGStreamType streamType;
@property (nonatomic) SRGQuality quality;
@property (nonatomic) NSInteger startBitRate;
@property (nonatomic) BOOL chaptersOnly;
@property (nonatomic) NSError *error;

// Save the URN sent to the social count view service, to not send it twice
@property (nonatomic) SRGMediaURN *socialCountViewURN;

@property (nonatomic) SRGLetterboxDataAvailability dataAvailability;
@property (nonatomic) SRGMediaPlayerPlaybackState playbackState;

@property (nonatomic) SRGDataProvider *dataProvider;
@property (nonatomic) SRGRequestQueue *requestQueue;

// Use timers (not time observers) so that updates are performed also when the controller is idle
@property (nonatomic) NSTimer *updateTimer;
@property (nonatomic) NSTimer *channelUpdateTimer;

// Timers for single metadata updates at start and end times
@property (nonatomic) NSTimer *startDateTimer;
@property (nonatomic) NSTimer *endDateTimer;
@property (nonatomic) NSTimer *liveStreamEndDateTimer;
@property (nonatomic) NSTimer *socialCountViewTimer;

@property (nonatomic, copy) void (^playerConfigurationBlock)(AVPlayer *player);
@property (nonatomic, copy) SRGLetterboxURLOverridingBlock contentURLOverridingBlock;

@property (nonatomic) NSTimeInterval updateInterval;
@property (nonatomic) NSTimeInterval channelUpdateInterval;

@property (nonatomic) NSDate *lastUpdateDate;

@property (nonatomic, getter=isTracked) BOOL tracked;

@end

@implementation SRGLetterboxController

@synthesize serviceURL = _serviceURL;
@synthesize globalHeaders = _globalHeaders;

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
        self.updateInterval = SRGLetterboxUpdateIntervalDefault;
        self.channelUpdateInterval = SRGLetterboxChannelUpdateIntervalDefault;
        
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
    self.updateTimer = nil;
    self.channelUpdateTimer = nil;
    self.startDateTimer = nil;
    self.endDateTimer = nil;
    self.liveStreamEndDateTimer = nil;
    self.socialCountViewTimer = nil;
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxPlaybackStateDidChangeNotification
                                                        object:self
                                                      userInfo:userInfo];
}

- (BOOL)isLive
{
    return self.mediaPlayerController.live;
}

- (CMTime)currentTime
{
    return self.mediaPlayerController.currentTime;
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

- (void)setUpdateInterval:(NSTimeInterval)updateInterval
{
    if (updateInterval < 10.) {
        SRGLetterboxLogWarning(@"controller", @"The mimimum update interval is 10 seconds. Fixed to 10 seconds.");
        updateInterval = 10.;
    }
    
    _updateInterval = updateInterval;
    
    @weakify(self)
    self.updateTimer = [NSTimer srg_scheduledTimerWithTimeInterval:updateInterval repeats:YES block:^(NSTimer * _Nonnull timer) {
        @strongify(self)
        
        [self updateMetadataWithCompletionBlock:^(NSError *error, BOOL URLChanged, NSError *previousError) {
            if (URLChanged || error) {
                [self stop];
            }
            // Start the player if the blocking reason changed from an not available state to an available one
            else if ([previousError.domain isEqualToString:SRGLetterboxErrorDomain] && previousError.code == SRGLetterboxErrorCodeNotAvailable) {
                [self playMedia:self.media withPreferredStreamType:self.streamType quality:self.quality startBitRate:self.startBitRate chaptersOnly:self.chaptersOnly];
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
    
    _channelUpdateInterval = channelUpdateInterval;
    
    @weakify(self)
    self.channelUpdateTimer = [NSTimer srg_scheduledTimerWithTimeInterval:channelUpdateInterval repeats:YES block:^(NSTimer * _Nonnull timer) {
       @strongify(self)
        
        [self updateChannel];
    }];
}

- (SRGMedia *)subdivisionMedia
{
    return [self.mediaComposition mediaForSubdivision:self.subdivision];
}

- (SRGMedia *)fullLengthMedia
{
    return self.mediaComposition.fullLengthMedia;
}

- (SRGResource *)resource
{
    return self.mediaPlayerController.resource;
}

- (NSURL *)contentURL
{
    return self.mediaPlayerController.contentURL;
}

- (BOOL)isContentURLOverridden
{
    if (! self.URN) {
        return NO;
    }
    
    return self.contentURLOverridingBlock && self.contentURLOverridingBlock(self.URN);
}

- (void)setUpdateTimer:(NSTimer *)updateTimer
{
    [_updateTimer invalidate];
    _updateTimer = updateTimer;
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

- (void)setLiveStreamEndDateTimer:(NSTimer *)liveStreamEndDateTimer
{
    [_liveStreamEndDateTimer invalidate];
    _liveStreamEndDateTimer = liveStreamEndDateTimer;
}

- (void)setSocialCountViewTimer:(NSTimer *)socialCountViewTimer
{
    [_socialCountViewTimer invalidate];
    _socialCountViewTimer = socialCountViewTimer;
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
        SRGSubdivision *mainSubdivision = (subdivision && [mediaComposition mediaForSubdivision:subdivision]) ? subdivision : mediaComposition.mainChapter;
        media = [mediaComposition mediaForSubdivision:mainSubdivision];
        mediaComposition = [mediaComposition mediaCompositionForSubdivision:mainSubdivision];
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
    
    // Schedule an update when the media starts
    NSTimeInterval startTimeInterval = [media.startDate timeIntervalSinceNow];
    if (startTimeInterval > 0.) {
        @weakify(self)
        self.startDateTimer = [NSTimer srg_scheduledTimerWithTimeInterval:startTimeInterval repeats:NO block:^(NSTimer * _Nonnull timer) {
            @strongify(self)
            [self updateMetadataWithCompletionBlock:^(NSError *error, BOOL URLChanged, NSError *previousError) {
                if (error) {
                    [self stop];
                }
                else {
                    [self playMedia:self.media withPreferredStreamType:self.streamType quality:self.quality startBitRate:self.startBitRate chaptersOnly:self.chaptersOnly];
                }
            }];
        }];
    }
    else {
        self.startDateTimer = nil;
    }
    
    // Schedule an update when the media ends
    NSTimeInterval endTimeInterval = [media.endDate timeIntervalSinceNow];
    if (endTimeInterval > 0.) {
        @weakify(self)
        self.endDateTimer = [NSTimer srg_scheduledTimerWithTimeInterval:endTimeInterval repeats:NO block:^(NSTimer * _Nonnull timer) {
            @strongify(self)
            
            [self updateWithError:SRGBlockingReasonErrorForMedia(self.media, [NSDate date])];
            [self notifyLivestreamEndWithMedia:self.mediaComposition.srgletterbox_liveMedia previousMedia:self.mediaComposition.srgletterbox_liveMedia];
            [self stop];
            
            [self updateMetadataWithCompletionBlock:nil];
        }];
    }
    else {
        self.endDateTimer = nil;
    }
    
    // Schedule an update when the associated livestream ends (if not the media itself)
    if (mediaComposition.srgletterbox_liveMedia && ! [mediaComposition.srgletterbox_liveMedia isEqual:media]) {
        NSTimeInterval endTimeInterval = [mediaComposition.srgletterbox_liveMedia.endDate timeIntervalSinceNow];
        if (endTimeInterval > 0.) {
            @weakify(self)
            self.liveStreamEndDateTimer = [NSTimer srg_scheduledTimerWithTimeInterval:endTimeInterval repeats:NO block:^(NSTimer * _Nonnull timer) {
                @strongify(self)
                
                [self notifyLivestreamEndWithMedia:self.mediaComposition.srgletterbox_liveMedia previousMedia:self.mediaComposition.srgletterbox_liveMedia];
                [self updateMetadataWithCompletionBlock:nil];
            }];
        }
        else {
            self.liveStreamEndDateTimer = nil;
        }
    }
    else {
        self.liveStreamEndDateTimer = nil;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxMetadataDidChangeNotification object:self userInfo:[userInfo copy]];
}

- (void)notifyLivestreamEndWithMedia:(SRGMedia *)media previousMedia:(SRGMedia *)previousMedia
{
    if (! media || (previousMedia && ! [media isEqual:previousMedia])) {
        return;
    }
    
    if (previousMedia) {
        if (previousMedia.contentType != SRGContentTypeLivestream && previousMedia.contentType != SRGContentTypeScheduledLivestream) {
            return;
        }
        
        if ([previousMedia blockingReasonAtDate:self.lastUpdateDate] == SRGBlockingReasonEndDate) {
            return;
        }
        
        if ((media.contentType != SRGContentTypeLivestream && media.contentType != SRGContentTypeScheduledLivestream)
            || ((media.contentType == SRGContentTypeLivestream || media.contentType == SRGContentTypeScheduledLivestream)
                    && [media blockingReasonAtDate:[NSDate date]] == SRGBlockingReasonEndDate)) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxLivestreamDidFinishNotification
                                                                    object:self
                                                                  userInfo:@{ SRGLetterboxMediaKey : previousMedia }];
        }
    }
    else {
        if ((media.contentType == SRGContentTypeLivestream || media.contentType == SRGContentTypeScheduledLivestream)
                && [media blockingReasonAtDate:[NSDate date]] == SRGBlockingReasonEndDate) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxLivestreamDidFinishNotification
                                                                object:self
                                                              userInfo:@{ SRGLetterboxMediaKey : media }];
        }
        
    }
}

- (void)updateMetadataWithCompletionBlock:(void (^)(NSError *error, BOOL URLChanged, NSError *previousError))completionBlock
{
    void (^updateCompletionBlock)(SRGMedia * _Nullable, NSError * _Nullable, BOOL, SRGMedia * _Nullable, NSError * _Nullable) = ^(SRGMedia * _Nullable media, NSError * _Nullable error, BOOL URLChanged, SRGMedia * _Nullable previousMedia, NSError * _Nullable previousError) {
        // Do not erase playback errors with successful metadata updates
        if (error || ! [self.error.domain isEqualToString:SRGLetterboxErrorDomain] || self.error.code != SRGLetterboxErrorCodeNotPlayable) {
            [self updateWithError:error];
        }
    
        [self notifyLivestreamEndWithMedia:media previousMedia:previousMedia];
        
        self.lastUpdateDate = [NSDate date];
        
        completionBlock ? completionBlock(error, URLChanged, previousError) : nil;
    };
    
    if (self.contentURLOverridden) {
        SRGRequest *mediaRequest = [self.dataProvider mediaWithURN:self.URN completionBlock:^(SRGMedia * _Nullable media, NSError * _Nullable error) {
            SRGMedia *previousMedia = self.media;
            
            if (media) {
                [self updateWithURN:nil media:media mediaComposition:nil subdivision:self.subdivision channel:self.channel];
            }
            else {
                media = previousMedia;
            }
            
            updateCompletionBlock(media, SRGBlockingReasonErrorForMedia(media, [NSDate date]), NO, previousMedia, SRGBlockingReasonErrorForMedia(previousMedia, self.lastUpdateDate));
        }];
        [self.requestQueue addRequest:mediaRequest resume:YES];
        return;
    }
    
    SRGRequest *mediaCompositionRequest = [self.dataProvider mediaCompositionWithURN:self.URN chaptersOnly:self.chaptersOnly completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        SRGMediaCompositionCompletionBlock mediaCompositionCompletionBlock = ^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
            SRGMediaComposition *previousMediaComposition = self.mediaComposition;
            
            SRGMedia *previousMedia = [previousMediaComposition mediaForSubdivision:previousMediaComposition.mainChapter];
            NSError *previousBlockingReasonError = SRGBlockingReasonErrorForMedia(previousMedia, self.lastUpdateDate);
            
            // Update metadata if retrieved, otherwise perform a check with the metadata we already have
            if (mediaComposition) {
                self.mediaPlayerController.mediaComposition = mediaComposition;
                [self updateWithURN:nil media:nil mediaComposition:mediaComposition subdivision:self.subdivision channel:self.channel];
            }
            else {
                mediaComposition = previousMediaComposition;
            }
            
            if (mediaComposition) {
                // Check whether the media is now blocked (conditions might have changed, e.g. user location or time)
                SRGMedia *media = [mediaComposition mediaForSubdivision:mediaComposition.mainChapter];
                NSError *blockingReasonError = SRGBlockingReasonErrorForMedia(media, [NSDate date]);
                if (blockingReasonError) {
                    updateCompletionBlock(mediaComposition.srgletterbox_liveMedia, blockingReasonError, NO, previousMediaComposition.srgletterbox_liveMedia, previousBlockingReasonError);
                    return;
                }
                
                if (previousMediaComposition) {
                    // Update the URL if resources change (also cover DVR to live change or conversely, aka DVR "kill switch")
                    NSSet<SRGResource *> *previousResources = [NSSet setWithArray:previousMediaComposition.mainChapter.playableResources];
                    NSSet<SRGResource *> *resources = [NSSet setWithArray:mediaComposition.mainChapter.playableResources];
                    if (! [previousResources isEqualToSet:resources]) {
                        updateCompletionBlock(mediaComposition.srgletterbox_liveMedia, (self.error) ? error : nil, YES, previousMediaComposition.srgletterbox_liveMedia, previousBlockingReasonError);
                        return;
                    }
                }
            }
            
            updateCompletionBlock(mediaComposition.srgletterbox_liveMedia, self.error ? error : nil, NO, previousMediaComposition.srgletterbox_liveMedia, previousBlockingReasonError);
        };
        
        if (error.code == SRGDataProviderErrorHTTP && [error.userInfo[SRGDataProviderHTTPStatusCodeKey] integerValue] == 404
                && self.mediaComposition && ! [self.mediaComposition.fullLengthMedia.URN isEqual:self.URN]) {
            SRGRequest *fullLengthMediaCompositionRequest = [self.dataProvider mediaCompositionWithURN:self.mediaComposition.fullLengthMedia.URN
                                                                                          chaptersOnly:self.chaptersOnly
                                                                                       completionBlock:mediaCompositionCompletionBlock];
            [self.requestQueue addRequest:fullLengthMediaCompositionRequest resume:YES];
        }
        else {
            mediaCompositionCompletionBlock(mediaComposition, error);
        }
    }];
    [self.requestQueue addRequest:mediaCompositionRequest resume:YES];
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
        SRGRequest *request = [self.dataProvider tvChannelWithUid:self.media.channel.uid completionBlock:completionBlock];
        [self.requestQueue addRequest:request resume:YES];
    }
    else if (self.media.mediaType == SRGMediaTypeAudio) {
        if (self.media.vendor == SRGVendorSRF && ! [self.media.uid isEqualToString:self.media.channel.uid]) {
            SRGRequest *request = [self.dataProvider radioChannelWithUid:self.media.channel.uid livestreamUid:self.media.uid completionBlock:completionBlock];
            [self.requestQueue addRequest:request resume:YES];
        }
        else {
            SRGRequest *request = [self.dataProvider radioChannelWithUid:self.media.channel.uid livestreamUid:nil completionBlock:completionBlock];
            [self.requestQueue addRequest:request resume:YES];
        }
    }
}

- (void)updateWithError:(NSError *)error
{
    if (! error) {
        self.error = nil;
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
        NSInteger code = (self.dataAvailability == SRGLetterboxDataAvailabilityNone) ? SRGLetterboxErrorCodeNotFound : SRGLetterboxErrorCodeNotPlayable;
        if ([error.domain isEqualToString:SRGDataProviderErrorDomain] && error.code == SRGDataProviderErrorHTTP && [error.userInfo[SRGDataProviderHTTPStatusCodeKey] integerValue] == 404) {
            code = SRGLetterboxErrorCodeNotFound;
        }
        self.error = [NSError errorWithDomain:SRGLetterboxErrorDomain
                                         code:code
                                     userInfo:@{ NSLocalizedDescriptionKey : SRGLetterboxLocalizedString(@"The media cannot be played", @"Message displayed when a media cannot be played for some reason (the user should not know about)"),
                                                 NSUnderlyingErrorKey : error }];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxPlaybackDidFailNotification object:self userInfo:@{ SRGLetterboxErrorKey : self.error }];
}

#pragma mark Playback

- (void)prepareToPlayURN:(SRGMediaURN *)URN withPreferredStreamType:(SRGStreamType)streamType quality:(SRGQuality)quality startBitRate:(NSInteger)startBitRate chaptersOnly:(BOOL)chaptersOnly completionHandler:(void (^)(void))completionHandler
{
    [self prepareToPlayURN:URN media:nil withPreferredStreamType:streamType quality:quality startBitRate:startBitRate chaptersOnly:chaptersOnly completionHandler:completionHandler];
}

- (void)prepareToPlayMedia:(SRGMedia *)media withPreferredStreamType:(SRGStreamType)streamType quality:(SRGQuality)quality startBitRate:(NSInteger)startBitRate chaptersOnly:(BOOL)chaptersOnly completionHandler:(void (^)(void))completionHandler
{
    [self prepareToPlayURN:nil media:media withPreferredStreamType:streamType quality:quality startBitRate:startBitRate chaptersOnly:chaptersOnly completionHandler:completionHandler];
}

- (void)prepareToPlayURN:(SRGMediaURN *)URN media:(SRGMedia *)media withPreferredStreamType:(SRGStreamType)streamType quality:(SRGQuality)quality startBitRate:(NSInteger)startBitRate chaptersOnly:(BOOL)chaptersOnly completionHandler:(void (^)(void))completionHandler
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
    if (self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateIdle && [self.URN isEqual:URN]) {
        return;
    }
    
    [self resetWithURN:URN media:media];
    
    // Save the settings for restarting after connection loss
    self.streamType = streamType;
    self.quality = quality;
    self.startBitRate = startBitRate;
    self.chaptersOnly = chaptersOnly;
    
    @weakify(self)
    self.requestQueue = [[SRGRequestQueue alloc] init];
    
    self.dataAvailability = SRGLetterboxDataAvailabilityLoading;
    
    // Apply overriding if available. Overriding requires a media to be available. No media composition is retrieved
    if (self.contentURLOverridingBlock) {
        NSURL *contentURL = self.contentURLOverridingBlock(URN);
        if (contentURL) {
            // Media readily available. Done
            if (media) {
                self.dataAvailability = SRGLetterboxDataAvailabilityLoaded;
                NSError *blockingReasonError = SRGBlockingReasonErrorForMedia(media, [NSDate date]);
                [self updateWithError:blockingReasonError];
                [self notifyLivestreamEndWithMedia:media previousMedia:nil];
                
                if (! blockingReasonError) {
                    [self.mediaPlayerController prepareToPlayURL:contentURL withCompletionHandler:completionHandler];
                }
            }
            // Retrieve the media
            else {
                void (^mediasCompletionBlock)(NSArray<SRGMedia *> * _Nullable, NSError * _Nullable) = ^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
                    if (error) {
                        self.dataAvailability = SRGLetterboxDataAvailabilityNone;
                        [self updateWithError:error];
                        return;
                    }
                    
                    self.dataAvailability = SRGLetterboxDataAvailabilityLoaded;
                    
                    [self updateWithURN:nil media:medias.firstObject mediaComposition:nil subdivision:nil channel:nil];
                    [self notifyLivestreamEndWithMedia:media previousMedia:nil];
                    
                    NSError *blockingReasonError = SRGBlockingReasonErrorForMedia(medias.firstObject, [NSDate date]);
                    if (blockingReasonError) {
                        [self updateWithError:blockingReasonError];
                    }
                    else {
                        [self.mediaPlayerController prepareToPlayURL:contentURL withCompletionHandler:completionHandler];
                    }
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
            self.dataAvailability = SRGLetterboxDataAvailabilityNone;
            [self updateWithError:error];
            return;
        }
        
        [self updateWithURN:nil media:nil mediaComposition:mediaComposition subdivision:mediaComposition.mainSegment channel:nil];
        [self updateChannel];
        [self notifyLivestreamEndWithMedia:mediaComposition.srgletterbox_liveMedia previousMedia:nil];
        
        // Do not go further if the content is blocked
        SRGMedia *media = [mediaComposition mediaForSubdivision:mediaComposition.mainChapter];
        NSError *blockingReasonError = SRGBlockingReasonErrorForMedia(media, [NSDate date]);
        if (blockingReasonError) {
            self.dataAvailability = SRGLetterboxDataAvailabilityLoaded;
            [self updateWithError:blockingReasonError];
            return;
        }
        
        @weakify(self)
        SRGRequest *playRequest = [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone streamType:streamType quality:quality startBitRate:startBitRate userInfo:nil resume:NO completionHandler:^(NSError * _Nonnull error) {
            @strongify(self)
            
            self.dataAvailability = SRGLetterboxDataAvailabilityLoaded;
            
            if (error) {
                [self updateWithError:error];
                return;
            }
            
            completionHandler ? completionHandler() : nil;
        }];
        
        if (playRequest) {
            [self.requestQueue addRequest:playRequest resume:YES];
        }
        else {
            self.dataAvailability = SRGLetterboxDataAvailabilityLoaded;
            
            NSError *error = [NSError errorWithDomain:SRGDataProviderErrorDomain
                                                 code:SRGDataProviderErrorCodeInvalidData
                                             userInfo:@{ NSLocalizedDescriptionKey : SRGLetterboxNonLocalizedString(@"No recommended streaming resources found") }];
            [self updateWithError:error];
        }
    }];
    [self.requestQueue addRequest:mediaCompositionRequest resume:YES];
}

- (void)play
{
    if (self.mediaPlayerController.contentURL) {
        [self.mediaPlayerController play];
    }
    else if (self.media) {
        [self playMedia:self.media withPreferredStreamType:self.streamType quality:self.quality startBitRate:self.startBitRate chaptersOnly:self.chaptersOnly];
    }
    else if (self.URN) {
        [self playURN:self.URN withPreferredStreamType:self.streamType quality:self.quality startBitRate:self.startBitRate chaptersOnly:self.chaptersOnly];
    };
}

- (void)pause
{
    [self.mediaPlayerController pause];
}

- (void)togglePlayPause
{
    if (self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying || self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateSeeking) {
        [self pause];
    }
    else {
        [self play];
    }
}

- (void)stop
{
    // Reset the player, including the attached URL. We keep the Letterbox controller context so that playback can
    // be restarted.
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
        [self prepareToPlayMedia:self.media withPreferredStreamType:self.streamType quality:self.quality startBitRate:self.startBitRate chaptersOnly:self.chaptersOnly completionHandler:prepareToPlayCompletionHandler];
    }
    else if (self.URN) {
        [self prepareToPlayURN:self.URN withPreferredStreamType:self.streamType quality:self.quality startBitRate:self.startBitRate chaptersOnly:self.chaptersOnly completionHandler:prepareToPlayCompletionHandler];
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
        self.dataProvider.globalHeaders = self.globalHeaders;
    }
    else {
        self.dataProvider = nil;
    }
    
    [self.mediaPlayerController reset];
    [self.requestQueue cancel];
    
    self.error = nil;
    
    self.lastUpdateDate = nil;
    
    self.dataAvailability = SRGLetterboxDataAvailabilityNone;
    
    self.streamType = SRGStreamTypeNone;
    self.quality = SRGQualityNone;
    self.startBitRate = 0;
    
    self.socialCountViewURN = nil;
    self.socialCountViewTimer = nil;
    
    // Update metadata first so that it is current when the player status is changed below
    [self updateWithURN:URN media:media mediaComposition:nil subdivision:nil channel:nil];
}

- (void)seekToTime:(CMTime)time withToleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter completionHandler:(void (^)(BOOL))completionHandler
{
    [self.mediaPlayerController seekToTime:time withToleranceBefore:toleranceBefore toleranceAfter:toleranceAfter completionHandler:completionHandler];
}

- (BOOL)switchToURN:(SRGMediaURN *)URN withCompletionHandler:(void (^)(BOOL))completionHandler
{
    for (SRGChapter *chapter in self.mediaComposition.chapters) {
        if ([chapter.URN isEqual:URN]) {
            return [self switchToSubdivision:chapter withCompletionHandler:completionHandler];
        }
        
        for (SRGSegment *segment in chapter.segments) {
            if ([segment.URN isEqual:URN]) {
                return [self switchToSubdivision:segment withCompletionHandler:completionHandler];
            }
        }
    }
    
    SRGLetterboxLogInfo(@"controller", @"The specified URN is not related to the current context. No switch will occur.");
    return NO;
}

- (BOOL)switchToSubdivision:(SRGSubdivision *)subdivision withCompletionHandler:(void (^)(BOOL))completionHandler
{
    if (! self.mediaComposition) {
        SRGLetterboxLogInfo(@"controller", @"No context is available. No switch will occur.");
        return NO;
    }
    
    // Build the media composition for the provided subdivision. Return `NO` if the subdivision is not related to the
    // media composition.
    SRGMediaComposition *mediaComposition = [self.mediaComposition mediaCompositionForSubdivision:subdivision];
    if (! mediaComposition) {
        SRGLetterboxLogInfo(@"controller", @"The subdivision is not related to the current context. No switch will occur.");
        return NO;
    }
    
    // If playing another media or if the player is not playing, restart
    if ([subdivision isKindOfClass:[SRGChapter class]]
            || self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle
            || self.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        NSError *blockingReasonError = SRGBlockingReasonErrorForMedia([mediaComposition mediaForSubdivision:mediaComposition.mainChapter], [NSDate date]);
        [self updateWithError:blockingReasonError];
        
        [self stop];
        self.socialCountViewURN = nil;
        self.socialCountViewTimer = nil;
        [self updateWithURN:nil media:nil mediaComposition:mediaComposition subdivision:subdivision channel:nil];
        
        if (! blockingReasonError) {
            SRGRequest *request = [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone streamType:self.streamType quality:self.quality startBitRate:self.startBitRate userInfo:nil resume:NO completionHandler:^(NSError * _Nullable error) {
                BOOL finished = (error == nil);
                completionHandler ? completionHandler(finished) : nil;
            }];
            [self.requestQueue addRequest:request resume:YES];
        }
    }
    // Playing another segment from the same media. Seek
    else if ([subdivision isKindOfClass:[SRGSegment class]]) {
        [self updateWithURN:nil media:nil mediaComposition:mediaComposition subdivision:subdivision channel:nil];
        [self.mediaPlayerController seekToSegment:(SRGSegment *)subdivision withCompletionHandler:^(BOOL finished) {
            [self.mediaPlayerController play];
            completionHandler ? completionHandler(finished) : nil;
        }];
    }
    else {
        return NO;
    }
    
    return YES;
}

#pragma mark Playback (convenience)

- (void)prepareToPlayURN:(SRGMediaURN *)URN withChaptersOnly:(BOOL)chaptersOnly completionHandler:(void (^)(void))completionHandler
{
    [self prepareToPlayURN:URN withPreferredStreamType:SRGStreamTypeNone quality:SRGQualityNone startBitRate:SRGLetterboxDefaultStartBitRate chaptersOnly:chaptersOnly completionHandler:completionHandler];
}

- (void)prepareToPlayMedia:(SRGMedia *)media withChaptersOnly:(BOOL)chaptersOnly completionHandler:(void (^)(void))completionHandler
{
    [self prepareToPlayMedia:media withPreferredStreamType:SRGStreamTypeNone quality:SRGQualityNone startBitRate:SRGLetterboxDefaultStartBitRate chaptersOnly:chaptersOnly completionHandler:completionHandler];
}

- (void)playURN:(SRGMediaURN *)URN withPreferredStreamType:(SRGStreamType)streamType quality:(SRGQuality)quality startBitRate:(NSInteger)startBitRate chaptersOnly:(BOOL)chaptersOnly
{
    @weakify(self)
    [self prepareToPlayURN:URN withPreferredStreamType:streamType quality:quality startBitRate:startBitRate chaptersOnly:chaptersOnly completionHandler:^{
        @strongify(self)
        
        [self play];
    }];
}

- (void)playMedia:(SRGMedia *)media withPreferredStreamType:(SRGStreamType)streamType quality:(SRGQuality)quality startBitRate:(NSInteger)startBitRate chaptersOnly:(BOOL)chaptersOnly
{
    @weakify(self)
    [self prepareToPlayMedia:media withPreferredStreamType:streamType quality:quality startBitRate:startBitRate chaptersOnly:chaptersOnly completionHandler:^{
        @strongify(self)
        
        [self play];
    }];
}

- (void)playURN:(SRGMediaURN *)URN withChaptersOnly:(BOOL)chaptersOnly
{
    [self playURN:URN withPreferredStreamType:SRGStreamTypeNone quality:SRGQualityNone startBitRate:SRGLetterboxDefaultStartBitRate chaptersOnly:chaptersOnly];
}

- (void)playMedia:(SRGMedia *)media withChaptersOnly:(BOOL)chaptersOnly
{
    [self playMedia:media withPreferredStreamType:SRGStreamTypeNone quality:SRGQualityNone startBitRate:SRGLetterboxDefaultStartBitRate chaptersOnly:chaptersOnly];
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
    if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR) {
        return [self canSkipForward];
    }
    
    if (self.mediaComposition.srgletterbox_liveMedia && ! [self.mediaComposition.srgletterbox_liveMedia isEqual:self.media]) {
        return [self.mediaComposition.srgletterbox_liveMedia blockingReasonAtDate:[NSDate date]] != SRGBlockingReasonEndDate;
    }
    else {
        return NO;
    }
}

- (BOOL)skipBackwardWithCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    return [self seekBackwardFromTime:[self seekStartTime] withCompletionHandler:completionHandler];
}

- (BOOL)skipForwardWithCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    return [self seekForwardFromTime:[self seekStartTime] withCompletionHandler:completionHandler];
}

#pragma mark Helpers

- (CMTime)seekStartTime
{
    return CMTIME_IS_INDEFINITE(self.mediaPlayerController.seekTargetTime) ? self.mediaPlayerController.currentTime : self.mediaPlayerController.seekTargetTime;
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

- (BOOL)seekBackwardFromTime:(CMTime)time withCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    if (! [self canSkipBackwardFromTime:time]) {
        return NO;
    }
    
    CMTime targetTime = CMTimeSubtract(time, CMTimeMakeWithSeconds(SRGLetterboxBackwardSkipInterval, NSEC_PER_SEC));
    [self seekToTime:targetTime withToleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity completionHandler:^(BOOL finished) {
        if (finished) {
            [self.mediaPlayerController play];
        }
        completionHandler ? completionHandler(finished) : nil;
    }];
    return YES;
}

- (BOOL)seekForwardFromTime:(CMTime)time withCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    if (! [self canSkipForwardFromTime:time]) {
        return NO;
    }
    
    CMTime targetTime = CMTimeAdd(time, CMTimeMakeWithSeconds(SRGLetterboxForwardSkipInterval, NSEC_PER_SEC));
    [self seekToTime:targetTime withToleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity completionHandler:^(BOOL finished) {
        if (finished) {
            [self.mediaPlayerController play];
        }
        completionHandler ? completionHandler(finished) : nil;
    }];
    return YES;
}

- (BOOL)skipToLiveWithCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    if (! [self canSkipToLive]) {
        return NO;
    }
    
    if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR) {
        [self seekToTime:CMTimeRangeGetEnd(self.mediaPlayerController.timeRange) withToleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity completionHandler:^(BOOL finished) {
            if (finished) {
                [self.mediaPlayerController play];
            }
            completionHandler ? completionHandler(finished) : nil;
        }];
        return YES;
    }
    else if (self.mediaComposition.srgletterbox_liveMedia) {
        return [self switchToURN:self.mediaComposition.srgletterbox_liveMedia.URN withCompletionHandler:completionHandler];
    }
    else {
        return NO;
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
        [self stop];
    }
    
    if (playbackState == SRGMediaPlayerPlaybackStatePlaying && self.mediaComposition && ! [self.socialCountViewURN isEqual:self.mediaComposition.mainChapter.URN] && ! self.socialCountViewTimer) {
        __block SRGSubdivision *subdivision = self.mediaComposition.mainChapter;
        
        static const NSTimeInterval kDefaultTimerInterval = 10.;
        NSTimeInterval timerInterval = kDefaultTimerInterval;
        if (subdivision.contentType != SRGContentTypeLivestream && subdivision.contentType != SRGContentTypeScheduledLivestream && subdivision.duration < kDefaultTimerInterval) {
            timerInterval = subdivision.duration * .8;
        }
        @weakify(self)
        self.socialCountViewTimer = [NSTimer srg_scheduledTimerWithTimeInterval:timerInterval repeats:NO block:^(NSTimer * _Nonnull timer) {
            @strongify(self)
            
            [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxSocialCountViewWillIncreaseNotification
                                                                object:self
                                                              userInfo:@{ SRGLetterboxSubdivisionKey : subdivision }];
            
            SRGRequest *request = [self.dataProvider increaseSocialCountForType:SRGSocialCountTypeSRGView subdivision:subdivision withCompletionBlock:^(SRGSocialCountOverview * _Nullable socialCountOverview, NSError * _Nullable error) {
                self.socialCountViewURN = socialCountOverview.URN;
                self.socialCountViewTimer = nil;
            }];
            [self.requestQueue addRequest:request resume:YES];
        }];
    }
    
    if (playbackState == SRGMediaPlayerPlaybackStateIdle) {
        self.socialCountViewTimer = nil;
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
    if (self.dataAvailability == SRGLetterboxDataAvailabilityLoading) {
        self.dataAvailability = SRGLetterboxDataAvailabilityLoaded;
    }
    [self updateWithError:notification.userInfo[SRGMediaPlayerErrorKey]];
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
