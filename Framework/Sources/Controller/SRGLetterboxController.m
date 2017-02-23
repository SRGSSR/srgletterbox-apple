//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxService+Private.h"
#import "SRGLetterboxError.h"
#import "SRGLetterboxLogger.h"

#import <FXReachability/FXReachability.h>
#import <libextobjc/libextobjc.h>
#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>
#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

const NSInteger SRGLetterboxAutomaticStartBitRate = -1;      // Reserved value for automatic start bit rate selection

const NSInteger SRGLetterboxBackwardSeekInterval = 30.;
const NSInteger SRGLetterboxForwardSeekInterval = 30.;

NSString * const SRGLetterboxMetadataDidChangeNotification = @"SRGLetterboxMetadataDidChangeNotification";

NSString * const SRGLetterboxURNKey = @"SRGLetterboxURNKey";
NSString * const SRGLetterboxMediaKey = @"SRGLetterboxMediaKey";
NSString * const SRGLetterboxMediaCompositionKey = @"SRGLetterboxMediaCompositionKey";
NSString * const SRGLetterboxChannelKey = @"SRGLetterboxChannelKey";

NSString * const SRGLetterboxPreviousURNKey = @"SRGLetterboxPreviousURNKey";
NSString * const SRGLetterboxPreviousMediaKey = @"SRGLetterboxPreviousMediaKey";
NSString * const SRGLetterboxPreviousMediaCompositionKey = @"SRGLetterboxPreviousMediaCompositionKey";
NSString * const SRGLetterboxPreviousChannelKey = @"SRGLetterboxPreviousChannelKey";

NSString * const SRGLetterboxPlaybackDidFailNotification = @"SRGLetterboxPlaybackDidFailNotification";

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

@interface SRGLetterboxController ()

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@property (nonatomic) SRGMediaURN *URN;
@property (nonatomic) SRGMedia *media;
@property (nonatomic) SRGMediaComposition *mediaComposition;
@property (nonatomic) SRGChannel *channel;
@property (nonatomic) SRGQuality preferredQuality;
@property (nonatomic) NSInteger preferredStartBitRate;
@property (nonatomic) NSError *error;

@property (nonatomic) SRGRequestQueue *requestQueue;

@property (nonatomic, weak) id streamAvailabilityPeriodicTimeObserver;
@property (nonatomic, weak) id channelUpdatePeriodicTimeObserver;

// For successive seeks, update the target time (previous seeks are cancelled). This makes it possible to seek faster
// to a desired location
@property (nonatomic) CMTime seekTargetTime;

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
        self.seekTargetTime = kCMTimeInvalid;
        
        // Also register the associated periodic time observers
        self.streamAvailabilityCheckInterval = 5. * 60.;
        self.channelUpdateInterval = 30.;
        
        self.resumesAfterRestart = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityDidChange:)
                                                     name:FXReachabilityStatusDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateDidChange:)
                                                     name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                   object:self.mediaPlayerController];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackDidFail:)
                                                     name:SRGMediaPlayerPlaybackDidFailNotification
                                                   object:self.mediaPlayerController];
    }
    return self;
}

- (void)dealloc
{
    [self.mediaPlayerController removePeriodicTimeObserver:self.streamAvailabilityPeriodicTimeObserver];
    [self.mediaPlayerController removePeriodicTimeObserver:self.channelUpdatePeriodicTimeObserver];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Getters and setters

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
    self.streamAvailabilityPeriodicTimeObserver = [self.mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(streamAvailabilityCheckInterval, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        @strongify(self)
        
        void (^completionBlock)(SRGMediaComposition * _Nullable, NSError * _Nullable) = ^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
            if (error) {
                return;
            }
            
            // If the user location has changed, she might be in a location where the content is now blocked
            SRGBlockingReason blockingReason = mediaComposition.mainChapter.blockingReason;
            if (blockingReason == SRGBlockingReasonGeoblocking) {
                [self.mediaPlayerController stop];
                
                NSError *error = [NSError errorWithDomain:SRGLetterboxErrorDomain
                                                     code:SRGLetterboxErrorCodeBlocked
                                                 userInfo:@{ NSLocalizedDescriptionKey : SRGMessageForBlockingReason(blockingReason) }];
                [self reportError:error];
                return;
            }
            
            // Update the URL if needed
            if (! [[self.mediaComposition.mainChapter resourcesForProtocol:SRGProtocolHLS_DVR] isEqual:[mediaComposition.mainChapter resourcesForProtocol:SRGProtocolHLS_DVR]]) {
                SRGMedia *media = [mediaComposition mediaForChapter:mediaComposition.mainChapter];
                [self playMedia:media withPreferredQuality:self.preferredQuality preferredStartBitRate:self.preferredStartBitRate];
            }
        };
        
        SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:self.serviceURL
                                                             businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierForVendor(self.media.vendor)];
        
        if (self.media.mediaType == SRGMediaTypeVideo) {
            [[dataProvider mediaCompositionForVideoWithUid:self.media.uid completionBlock:completionBlock] resume];
        }
        else if (self.media.mediaType == SRGMediaTypeAudio) {
            [[dataProvider mediaCompositionForAudioWithUid:self.media.uid completionBlock:completionBlock] resume];
        }
    }];
}

- (void)setChannelUpdateInterval:(NSTimeInterval)channelUpdateInterval
{
    if (channelUpdateInterval < 10.) {
        SRGLetterboxLogWarning(@"controller", @"The mimimum now and next update interval is 10 seconds. Fixed to 10 seconds.");
        channelUpdateInterval = 10.;
    }
    
    @weakify(self)
    self.channelUpdatePeriodicTimeObserver = [self.mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(channelUpdateInterval, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        @strongify(self)
        
        [self updateChannel];
    }];
}

#pragma mark Data

// Pass in which data is available, the method will ensure that the data is consistent based on the most comprehensive
// information available (media composition first, then media, finally URN). Less comprehensive data will be ignored
- (void)updateWithURN:(SRGMediaURN *)URN media:(SRGMedia *)media mediaComposition:(SRGMediaComposition *)mediaComposition channel:(SRGChannel *)channel
{
    if (mediaComposition) {
        media = [mediaComposition mediaForSegment:mediaComposition.mainSegment ?: mediaComposition.mainChapter];
    }
    
    if (media) {
        URN = media.URN;
    }
    
    SRGMediaURN *previousURN = self.URN;
    SRGMedia *previousMedia = self.media;
    SRGMediaComposition *previousMediaComposition = self.mediaComposition;
    SRGChannel *previousChannel = self.channel;
    
    self.URN = URN;
    self.media = media;
    self.mediaComposition = mediaComposition;
    self.channel = channel;
    
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
    if (previousChannel) {
        userInfo[SRGLetterboxPreviousChannelKey] = previousChannel;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxMetadataDidChangeNotification object:self userInfo:[userInfo copy]];
}

- (void)updateChannel
{
    // Only for livestreams with a channel uid
    if (self.media.contentType != SRGContentTypeLivestream || ! self.media.channel.uid) {
        return;
    }
    
    void (^completionBlock)(SRGChannel * _Nullable, NSError * _Nullable) = ^(SRGChannel * _Nullable channel, NSError * _Nullable error) {
        if (error) {
            return;
        }
        
        [self updateWithURN:self.URN media:self.media mediaComposition:self.mediaComposition channel:channel];
    };
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:self.serviceURL
                                                         businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierForVendor(self.media.vendor)];
    if (self.media.mediaType == SRGMediaTypeVideo) {
        [[dataProvider videoChannelWithUid:self.media.channel.uid completionBlock:completionBlock] resume];
    }
    else if (self.media.mediaType == SRGMediaTypeAudio) {
        // TODO: Regional radio support
        [[dataProvider audioChannelWithUid:self.media.channel.uid livestreamUid:nil completionBlock:completionBlock] resume];
    }
}

#pragma mark Playback

- (void)prepareToPlayURN:(SRGMediaURN *)URN withPreferredQuality:(SRGQuality)preferredQuality preferredStartBitRate:(NSInteger)preferredStartBitRate completionHandler:(void (^)(void))completionHandler
{
    [self prepareToPlayURN:URN media:nil withPreferredQuality:preferredQuality preferredStartBitRate:preferredStartBitRate completionHandler:completionHandler];
}

- (void)prepareToPlayMedia:(SRGMedia *)media withPreferredQuality:(SRGQuality)preferredQuality preferredStartBitRate:(NSInteger)preferredStartBitRate completionHandler:(void (^)(void))completionHandler
{
    [self prepareToPlayURN:nil media:media withPreferredQuality:preferredQuality preferredStartBitRate:preferredStartBitRate completionHandler:completionHandler];
}

- (void)prepareToPlayURN:(SRGMediaURN *)URN media:(SRGMedia *)media withPreferredQuality:(SRGQuality)preferredQuality preferredStartBitRate:(NSInteger)preferredStartBitRate completionHandler:(void (^)(void))completionHandler
{
    if (media) {
        URN = media.URN;
    }
    
    if (preferredStartBitRate < 0 && preferredStartBitRate != SRGLetterboxAutomaticStartBitRate) {
        preferredStartBitRate = 0;
    }
    
    // If already playing the media, does nothing
    if (self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateIdle && [self.media.URN isEqual:URN]) {
        return;
    }
    
    [self resetWithURN:URN media:media];
    
    // Save the quality settings for restarting after connection loss
    self.preferredQuality = preferredQuality;
    self.preferredStartBitRate = preferredStartBitRate;
    
    @weakify(self)
    self.requestQueue = [[SRGRequestQueue alloc] initWithStateChangeBlock:^(BOOL finished, NSError * _Nullable error) {
        @strongify(self)
        
        if (finished) {
            [self reportError:error];
        }
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:self.serviceURL
                                                         businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierForVendor(URN.vendor)];
    
    // Apply overriding if available. Overriding requires a media to be available. No media composition is retrieved
    if (self.contentURLOverridingBlock) {
        NSURL *contentURL = self.contentURLOverridingBlock(URN);
        if (contentURL) {
            // Media readily available. Done
            if (media) {
                [self.mediaPlayerController playURL:contentURL];
            }
            // Retrieve the media
            else {
                void (^mediasCompletionBlock)(NSArray<SRGMedia *> * _Nullable, NSError * _Nullable) = ^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
                    if (error) {
                        [self.requestQueue reportError:error];
                        return;
                    }
                    
                    [self updateWithURN:nil media:medias.firstObject mediaComposition:nil channel:nil];
                    [self.mediaPlayerController playURL:contentURL];
                };
                
                if (URN.mediaType == SRGMediaTypeVideo) {
                    SRGRequest *mediaRequest = [dataProvider videosWithUids:@[URN.uid] completionBlock:mediasCompletionBlock];
                    [self.requestQueue addRequest:mediaRequest resume:YES];
                }
                else {
                    SRGRequest *mediaRequest = [dataProvider audiosWithUids:@[URN.uid] completionBlock:mediasCompletionBlock];
                    [self.requestQueue addRequest:mediaRequest resume:YES];
                }
            }
            return;
        }
    }
    
    void (^mediaCompositionCompletionBlock)(SRGMediaComposition * _Nullable, NSError * _Nullable) = ^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        @strongify(self)
        
        if (error) {
            [self.requestQueue reportError:error];
            return;
        }
        
        [self updateWithURN:nil media:nil mediaComposition:mediaComposition channel:nil];
        [self updateChannel];
        
        // Do not go further if the content is blocked
        SRGBlockingReason blockingReason = mediaComposition.mainChapter.blockingReason;
        if (blockingReason == SRGBlockingReasonGeoblocking) {
            NSError *error = [NSError errorWithDomain:SRGLetterboxErrorDomain
                                                 code:SRGLetterboxErrorCodeBlocked
                                             userInfo:@{ NSLocalizedDescriptionKey : SRGMessageForBlockingReason(mediaComposition.mainChapter.blockingReason) }];
            [self.requestQueue reportError:error];
            return;
        }
        
        // Start bit rate for automatic mode is 800 kbps
        NSInteger startBitRate = (preferredStartBitRate == SRGLetterboxAutomaticStartBitRate) ? 800 : preferredStartBitRate;
        
        @weakify(self)
        SRGRequest *playRequest = [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredProtocol:SRGProtocolNone preferredQuality:preferredQuality preferredStartBitRate:startBitRate userInfo:nil resume:NO completionHandler:^(NSError * _Nonnull error) {
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
                                             userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The media cannot be played", nil) }];
            [self.requestQueue reportError:error];
        }
    };
    
    if (URN.mediaType == SRGMediaTypeVideo) {
        SRGRequest *mediaCompositionRequest = [dataProvider mediaCompositionForVideoWithUid:URN.uid completionBlock:mediaCompositionCompletionBlock];
        [self.requestQueue addRequest:mediaCompositionRequest resume:YES];
    }
    else if (URN.mediaType == SRGMediaTypeAudio) {
        SRGRequest *mediaCompositionRequest = [dataProvider mediaCompositionForAudioWithUid:URN.uid completionBlock:mediaCompositionCompletionBlock];
        [self.requestQueue addRequest:mediaCompositionRequest resume:YES];
    }
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
    [self.mediaPlayerController stop];
}

- (void)restart
{
    @weakify(self)
    void (^completionHandler)(void) = ^{
        @strongify(self)
        
        if (self.resumesAfterRestart) {
            [self play];
        }
    };
    
    // Reuse the media if available (so that the information already available to clients is not reduced)
    if (self.media) {
        [self prepareToPlayMedia:self.media withPreferredQuality:self.preferredQuality preferredStartBitRate:self.preferredStartBitRate completionHandler:completionHandler];
    }
    else if (self.URN) {
        [self prepareToPlayURN:self.URN withPreferredQuality:self.preferredQuality preferredStartBitRate:self.preferredStartBitRate completionHandler:completionHandler];
    }
}

- (void)reset
{
    [self resetWithURN:nil media:nil];
}

- (void)resetWithURN:(SRGMediaURN *)URN media:(SRGMedia *)media
{
    self.error = nil;
    self.seekTargetTime = kCMTimeInvalid;
    
    self.preferredQuality = SRGQualityNone;
    self.preferredStartBitRate = 0;
    
    [self.mediaPlayerController reset];
    [self.requestQueue cancel];
    
    [self updateWithURN:URN media:media mediaComposition:nil channel:nil];
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

- (void)prepareToPlayURN:(SRGMediaURN *)URN
   withCompletionHandler:(void (^)(void))completionHandler
{
    [self prepareToPlayURN:URN withPreferredQuality:SRGQualityNone preferredStartBitRate:SRGLetterboxAutomaticStartBitRate completionHandler:completionHandler];
}

- (void)prepareToPlayMedia:(SRGMedia *)media
     withCompletionHandler:(void (^)(void))completionHandler
{
    [self prepareToPlayMedia:media withPreferredQuality:SRGQualityNone preferredStartBitRate:SRGLetterboxAutomaticStartBitRate completionHandler:completionHandler];
}

- (void)playURN:(SRGMediaURN *)URN withPreferredQuality:(SRGQuality)preferredQuality preferredStartBitRate:(NSInteger)preferredStartBitRate
{
    @weakify(self)
    [self prepareToPlayURN:URN withPreferredQuality:preferredQuality preferredStartBitRate:preferredStartBitRate completionHandler:^{
        @strongify(self)
        
        [self play];
    }];
}

- (void)playMedia:(SRGMedia *)media withPreferredQuality:(SRGQuality)preferredQuality preferredStartBitRate:(NSInteger)preferredStartBitRate
{
    @weakify(self)
    [self prepareToPlayMedia:media withPreferredQuality:preferredQuality preferredStartBitRate:preferredStartBitRate completionHandler:^{
        @strongify(self)
        
        [self play];
    }];
}

- (void)playURN:(SRGMediaURN *)URN
{
    [self playURN:URN withPreferredQuality:SRGQualityNone preferredStartBitRate:SRGLetterboxAutomaticStartBitRate];
}

- (void)playMedia:(SRGMedia *)media
{
    [self playMedia:media withPreferredQuality:SRGQualityNone preferredStartBitRate:SRGLetterboxAutomaticStartBitRate];
}

#pragma mark Standard seeks

- (BOOL)canSeekBackward
{
    return [self canSeekBackwardFromTime:[self seekStartTime]];
}

- (BOOL)canSeekForward
{
    return [self canSeekForwardFromTime:[self seekStartTime]];
}

- (BOOL)canSeekToLive
{
    return (self.media.contentType == SRGContentTypeLivestream && [self canSeekForward]);
}

- (void)seekBackwardWithCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    [self seekBackwardFromTime:[self seekStartTime] withCompletionHandler:completionHandler];
}

- (void)seekForwardWithCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    [self seekForwardFromTime:[self seekStartTime] withCompletionHandler:completionHandler];
}

#pragma mark Helpers

- (CMTime)seekStartTime
{
    return CMTIME_IS_VALID(self.seekTargetTime) ? self.seekTargetTime : self.mediaPlayerController.player.currentTime;
}

- (BOOL)canSeekBackwardFromTime:(CMTime)time
{
    if (CMTIME_IS_INVALID(time)) {
        return NO;
    }
    
    SRGMediaPlayerStreamType streamType = self.mediaPlayerController.streamType;
    return (streamType == SRGMediaPlayerStreamTypeOnDemand || streamType == SRGMediaPlayerStreamTypeDVR);
}

- (BOOL)canSeekForwardFromTime:(CMTime)time
{
    if (CMTIME_IS_INVALID(time)) {
        return NO;
    }
    
    SRGMediaPlayerController *mediaPlayerController = self.mediaPlayerController;
    return (mediaPlayerController.streamType == SRGMediaPlayerStreamTypeOnDemand && CMTimeGetSeconds(time) + SRGLetterboxForwardSeekInterval < CMTimeGetSeconds(mediaPlayerController.player.currentItem.duration))
        || (mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR && ! mediaPlayerController.live);
}

- (void)seekBackwardFromTime:(CMTime)time withCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    if (![self canSeekBackwardFromTime:time]) {
        completionHandler ? completionHandler(NO) : nil;
        return;
    }
    
    self.seekTargetTime = CMTimeSubtract(time, CMTimeMakeWithSeconds(SRGLetterboxBackwardSeekInterval, NSEC_PER_SEC));
    [self.mediaPlayerController seekEfficientlyToTime:self.seekTargetTime withCompletionHandler:^(BOOL finished) {
        if (finished) {
            [self.mediaPlayerController play];
        }
        completionHandler ? completionHandler(finished) : nil;
    }];
}

- (void)seekForwardFromTime:(CMTime)time withCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    if (![self canSeekForwardFromTime:time]) {
        completionHandler ? completionHandler(NO) : nil;
        return;
    }
    
    self.seekTargetTime = CMTimeAdd(time, CMTimeMakeWithSeconds(SRGLetterboxForwardSeekInterval, NSEC_PER_SEC));
    [self.mediaPlayerController seekEfficientlyToTime:self.seekTargetTime withCompletionHandler:^(BOOL finished) {
        if (finished) {
            [self.mediaPlayerController play];
        }
        completionHandler ? completionHandler(finished) : nil;
    }];
}

- (void)seekToLiveWithCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    if (self.media.contentType == SRGContentTypeLivestream) {
        CMTimeRange timeRange = self.mediaPlayerController.timeRange;
        
        [self.mediaPlayerController seekEfficientlyToTime:CMTimeRangeGetEnd(timeRange) withCompletionHandler:^(BOOL finished) {
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
        [self restart];
    }
}

- (void)playbackStateDidChange:(NSNotification *)notification
{
    SRGMediaPlayerPlaybackState playbackState = [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue];
    
    // Do not let pause live streams, stop playback
    if (self.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeLive && playbackState == SRGMediaPlayerPlaybackStatePaused) {
        [self.mediaPlayerController stop];
    }
    
    if (playbackState != SRGMediaPlayerPlaybackStateSeeking) {
        self.seekTargetTime = kCMTimeInvalid;
    }
}

- (void)playbackDidFail:(NSNotification *)notification
{
    [self reportError:notification.userInfo[SRGMediaPlayerErrorKey]];
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
