//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGDataProvider+SRGLetterbox.h"
#import "SRGLetterboxError.h"

#import <FXReachability/FXReachability.h>
#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>
#import <SRGAnalytics_MediaPlayer/SRGAnalytics_MediaPlayer.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

const NSInteger SRGLetterboxBackwardSeekInterval = 30.;
const NSInteger SRGLetterboxForwardSeekInterval = 30.;

NSString * const SRGLetterboxMetadataDidChangeNotification = @"SRGLetterboxMetadataDidChangeNotification";

NSString * const SRGLetterboxURNKey = @"SRGLetterboxURNKey";
NSString * const SRGLetterboxMediaKey = @"SRGLetterboxMediaKey";
NSString * const SRGLetterboxMediaCompositionKey = @"SRGLetterboxMediaCompositionKey";

NSString * const SRGLetterboxPreviousURNKey = @"SRGLetterboxPreviousURNKey";
NSString * const SRGLetterboxPreviousMediaKey = @"SRGLetterboxPreviousMediaKey";
NSString * const SRGLetterboxPreviousMediaCompositionKey = @"SRGLetterboxPreviousMediaCompositionKey";

NSString * const SRGLetterboxPlaybackDidFailNotification = @"SRGLetterboxPlaybackDidFailNotification";

NSString * const SRGLetterboxErrorKey = @"SRGLetterboxErrorKey";

@interface SRGLetterboxController ()

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@property (nonatomic) SRGMediaURN *URN;
@property (nonatomic) SRGMedia *media;
@property (nonatomic) SRGMediaComposition *mediaComposition;
@property (nonatomic) SRGQuality preferredQuality;
@property (nonatomic) NSError *error;

@property (nonatomic) SRGRequestQueue *requestQueue;

// For successive seeks, update the target time (previous seeks are cancelled). This makes it possible to seek faster
// to a desired location
@property (nonatomic) CMTime seekTargetTime;

@end

@implementation SRGLetterboxController

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.mediaPlayerController = [[SRGMediaPlayerController alloc] init];
        self.seekTargetTime = kCMTimeInvalid;
        
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Data

// Pass in which data is available, the method will ensure that the data is consistent based on the most comprehensive
// information available (media composition first, then media, finally URN). Less comprehensive data will be ignored
- (void)updateWithURN:(SRGMediaURN *)URN media:(SRGMedia *)media mediaComposition:(SRGMediaComposition *)mediaComposition
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
    
    self.URN = URN;
    self.media = media;
    self.mediaComposition = mediaComposition;
    
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
    if (previousURN) {
        userInfo[SRGLetterboxPreviousURNKey] = previousURN;
    }
    if (previousMedia) {
        userInfo[SRGLetterboxPreviousMediaKey] = previousMedia;
    }
    if (previousMediaComposition) {
        userInfo[SRGLetterboxPreviousMediaCompositionKey] = previousMediaComposition;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxMetadataDidChangeNotification object:self userInfo:[userInfo copy]];
}

#pragma mark Playback

- (void)playURN:(SRGMediaURN *)URN withPreferredQuality:(SRGQuality)preferredQuality
{
    [self playURN:URN media:nil withPreferredQuality:preferredQuality];
}

- (void)playMedia:(SRGMedia *)media withPreferredQuality:(SRGQuality)preferredQuality
{
    [self playURN:nil media:media withPreferredQuality:preferredQuality];
}

- (void)playURN:(SRGMediaURN *)URN media:(SRGMedia *)media withPreferredQuality:(SRGQuality)preferredQuality
{
    if (media) {
        URN = media.URN;
    }
    
    // If already playing the media, does nothing
    if (self.mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateIdle && [self.media.URN isEqual:URN]) {
        return;
    }
    
    [self resetWithURN:URN media:media];
    
    self.requestQueue = [[SRGRequestQueue alloc] initWithStateChangeBlock:^(BOOL finished, NSError * _Nullable error) {
        if (finished) {
            [self reportError:error];
        }
    }];
    
    void (^mediaCompositionCompletionBlock)(SRGMediaComposition * _Nullable, NSError * _Nullable) = ^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        if (error) {
            [self.requestQueue reportError:error];
            return;
        }
        
        [self updateWithURN:nil media:nil mediaComposition:mediaComposition];
        
        SRGRequest *playRequest = [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredProtocol:SRGProtocolNone preferredQuality:preferredQuality userInfo:nil resume:NO completionHandler:^(NSError * _Nonnull error) {
            [self.requestQueue reportError:error];
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
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:[SRGDataProvider serviceURL]
                                                         businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierForVendor(URN.vendor)];
    
    if (URN.mediaType == SRGMediaTypeVideo) {
        SRGRequest *mediaCompositionRequest = [dataProvider mediaCompositionForVideoWithUid:URN.uid completionBlock:mediaCompositionCompletionBlock];
        [self.requestQueue addRequest:mediaCompositionRequest resume:YES];
    }
    else if (URN.mediaType == SRGMediaTypeAudio) {
        SRGRequest *mediaCompositionRequest = [dataProvider mediaCompositionForAudioWithUid:URN.uid completionBlock:mediaCompositionCompletionBlock];
        [self.requestQueue addRequest:mediaCompositionRequest resume:YES];
    }
}

- (void)reset
{
    [self resetWithURN:nil media:nil];
}

- (void)resetWithURN:(SRGMediaURN *)URN media:(SRGMedia *)media
{
    self.error = nil;
    
    [self.mediaPlayerController reset];
    [self.requestQueue cancel];
    
    [self updateWithURN:URN media:media mediaComposition:nil];
}

- (void)reportError:(NSError *)error
{
    if (! error) {
        return;
    }
    
    // Use a friendly error message for network errors (might be a connection loss, incorrect proxy settings, etc.)
    if ([error.domain isEqualToString:(NSString *)kCFErrorDomainCFNetwork] || [error.domain isEqualToString:NSURLErrorDomain]) {
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

#pragma mark Standard seeks

- (BOOL)canSeekBackward
{
    return [self canSeekBackwardFromTime:[self seekStartTime]];
}

- (BOOL)canSeekForward
{
    return [self canSeekForwardFromTime:[self seekStartTime]];
}

- (void)seekBackwardWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler
{
    [self seekBackwardFromTime:[self seekStartTime] withCompletionHandler:completionHandler];
}

- (void)seekForwardWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler
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
        || (mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR && !mediaPlayerController.live);
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

#pragma mark Notifications

- (void)reachabilityDidChange:(NSNotification *)notification
{
    if ([FXReachability sharedInstance].reachable) {
        if (self.media) {
            [self playMedia:self.media withPreferredQuality:self.preferredQuality];
        }
        else if (self.URN) {
            [self playURN:self.URN withPreferredQuality:self.preferredQuality];
        }
    }
}

- (void)playbackStateDidChange:(NSNotification *)notification
{
    SRGMediaPlayerPlaybackState playbackState = [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue];
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
    return [NSString stringWithFormat:@"<%@: %p; URN: %@; media: %@; mediaComposition: %@; error: %@; mediaPlayerController: %@>",
            [self class],
            self,
            self.URN,
            self.media,
            self.mediaComposition,
            self.error,
            self.mediaPlayerController];
}

@end
