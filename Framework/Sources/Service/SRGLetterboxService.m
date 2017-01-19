//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxService.h"

#import "SRGLetterboxError.h"
#import "UIDevice+SRGLetterbox.h"
#import "SRGDataProvider+SRGLetterbox.h"

#import <libextobjc/libextobjc.h>
#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>
#import <YYWebImage/YYWebImage.h>
#import <FXReachability/FXReachability.h>

NSString * const SRGLetterboxServiceMetadataDidChangeNotification = @"SRGLetterboxServiceMetadataDidChangeNotification";

NSString * const SRGLetterboxServiceURNKey = @"SRGLetterboxServiceURNKey";
NSString * const SRGLetterboxServiceMediaKey = @"SRGLetterboxServiceMediaKey";
NSString * const SRGLetterboxServiceMediaCompositionKey = @"SRGLetterboxServiceMediaCompositionKey";
NSString * const SRGLetterboxServicePreferredQualityKey = @"SRGLetterboxServicePreferredQualityKey";

NSString * const SRGLetterboxServicePreviousURNKey = @"SRGLetterboxServicePreviousURNKey";
NSString * const SRGLetterboxServicePreviousMediaKey = @"SRGLetterboxServicePreviousMediaKey";
NSString * const SRGLetterboxServicePreviousMediaCompositionKey = @"SRGLetterboxServicePreviousMediaCompositionKey";
NSString * const SRGLetterboxServicePreviousPreferredQualityKey = @"SRGLetterboxServicePreviousPreferredQualityKey";

NSString * const SRGLetterboxServicePlaybackDidFailNotification = @"SRGLetterboxServicePlaybackDidFailNotification";

@interface SRGLetterboxService ()

@property (nonatomic, weak) id periodicTimeObserver;

@property (nonatomic) NSString *urn;
@property (nonatomic) SRGMedia *media;
@property (nonatomic) SRGMediaComposition *mediaComposition;
@property (assign)    SRGQuality preferredQuality;
@property (nonatomic) NSError *error;

@property (nonatomic) YYWebImageOperation *imageOperation;
@property (nonatomic) SRGRequestQueue *requestQueue;

@end

@implementation SRGLetterboxService

#pragma mark Class methods

+ (SRGLetterboxService *)sharedService
{
    static SRGLetterboxService *s_sharedService;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_sharedService = [SRGLetterboxService new];
    });
    return s_sharedService;
}

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        NSAssert([SRGAnalyticsTracker sharedTracker].started, @"The SRGAnalyticsTracker shared instance must be started before accessing the Letterbox service");
        NSAssert([SRGDataProvider currentDataProvider], @"A current SRGDataProvider must have been defined before accessing the Letterbox service");
        
        self.controller = [[SRGLetterboxController alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(audioSessionWasInterrupted:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityDidChange:)
                                                     name:FXReachabilityStatusDidChangeNotification
                                                   object:nil];
        
        [self setupRemoteCommandCenter];
    }
    return self;
}

#pragma mark Getters and setters

- (void)setController:(SRGLetterboxController *)controller
{
    if (_controller) {
        _controller.playerConfigurationBlock = ^(AVPlayer *player) {
            player.allowsExternalPlayback = NO;
        };
        [_controller reloadPlayerConfiguration];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                      object:_controller];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGMediaPlayerPlaybackDidFailNotification
                                                      object:_controller];
        
        [_controller removePeriodicTimeObserver:self.periodicTimeObserver];
    }
    
    _controller = controller;
    
    [self updateRemoteCommandCenter];
    [self updateNowPlayingInformation];
    [self updateNowPlayingPlaybackInformation];
    
    if (controller) {
        controller.playerConfigurationBlock = ^(AVPlayer *player) {
            // Use mirroring when in presentation mode
            player.allowsExternalPlayback = YES;
//            player.usesExternalPlaybackWhileExternalScreenIsActive = ! ApplicationSettingPresenterModeEnabled();
            
            // Only update the audio session if needed to avoid audio hiccups
            NSString *mode = (self.media.mediaType == SRGMediaTypeVideo) ? AVAudioSessionModeMoviePlayback : AVAudioSessionModeDefault;
            if (! [[AVAudioSession sharedInstance].mode isEqualToString:mode]) {
                [[AVAudioSession sharedInstance] setMode:mode error:NULL];
            }
        };
        
        @weakify(self)
        controller.pictureInPictureControllerCreationBlock = ^(AVPictureInPictureController *pictureInPictureController) {
            @strongify(self)
            
            pictureInPictureController.delegate = self;
        };
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateDidChange:)
                                                     name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                   object:controller];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackDidFail:)
                                                     name:SRGMediaPlayerPlaybackDidFailNotification
                                                   object:controller];
        
        self.periodicTimeObserver = [controller addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
            [self updateNowPlayingPlaybackInformation];
            [self updateRemoteCommandCenter];
        }];
    }
}

- (BOOL)isPictureInPictureActive
{
    return self.controller.pictureInPictureController.pictureInPictureActive;
}

#pragma mark Data

- (void)updateWithURN:(NSString *)urn media:(SRGMedia *)media mediaComposition:(SRGMediaComposition *)mediaComposition preferredQuality:(SRGQuality)preferredQuality
{
    if (media) {
        urn = media.URN;
    }
    
    if ([self.urn isEqualToString:urn] && self.media == media && self.mediaComposition == mediaComposition) {
        return;
    }
    
    NSString *previousURN = self.urn;
    SRGMedia *previousMedia = self.media;
    SRGMediaComposition *previousMediaComposition = self.mediaComposition;
    SRGQuality previousPreferredQuality = self.preferredQuality;
    
    self.urn = media.URN;
    self.media = media;
    self.mediaComposition = mediaComposition;
    self.preferredQuality = preferredQuality;
    
    if (! media || ! urn) {
        NSAssert(mediaComposition == nil, @"No media composition is expected when updating with no media or media uid");
        
        self.error = nil;
        
        [self.controller reset];
        [self.requestQueue cancel];
        [self.imageOperation cancel];
        
        [self updateRemoteCommandCenter];
        [self updateNowPlayingInformation];
        [self updateNowPlayingPlaybackInformation];
    }
    
    NSMutableDictionary<NSString *, id> *userInfo = [NSMutableDictionary dictionary];
    if (urn) {
        userInfo[SRGLetterboxServiceURNKey] = urn;
    }
    if (media) {
        userInfo[SRGLetterboxServiceMediaKey] = media;
    }
    if (mediaComposition) {
        userInfo[SRGLetterboxServiceMediaCompositionKey] = mediaComposition;
    }
    if (preferredQuality) {
        userInfo[SRGLetterboxServicePreferredQualityKey] = @(preferredQuality);
    }
    if (previousURN) {
        userInfo[SRGLetterboxServicePreviousURNKey] = previousURN;
    }
    if (previousMedia) {
        userInfo[SRGLetterboxServicePreviousMediaKey] = previousMedia;
    }
    if (previousMediaComposition) {
        userInfo[SRGLetterboxServicePreviousMediaCompositionKey] = previousMediaComposition;
    }
    if (previousPreferredQuality) {
        userInfo[SRGLetterboxServicePreviousPreferredQualityKey] = @(previousPreferredQuality);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxServiceMetadataDidChangeNotification object:self userInfo:[userInfo copy]];
}

#pragma mark Playback

- (void)playURN:(NSString *)urn withPreferredQuality:(SRGQuality)preferredQuality
{
    [self playURN:urn media:nil withPreferredQuality:preferredQuality];
}

- (void)playMedia:(SRGMedia *)media withPreferredQuality:(SRGQuality)preferredQuality
{
    [self playURN:media.URN media:media withPreferredQuality:preferredQuality];
}

- (void)playURN:(NSString *)mediaURN media:(SRGMedia *)media withPreferredQuality:(SRGQuality)preferredQuality
{
    if (media) {
        mediaURN = media.URN;
    }
    
    // If already playing the media, does nothing
    if (self.controller.playbackState != SRGMediaPlayerPlaybackStateIdle
            && [self.media.URN isEqualToString:mediaURN]) {
        return;
    }
    
    [self updateWithURN:mediaURN media:media mediaComposition:nil preferredQuality:preferredQuality];
    
    // Perform media-dependent updates
    [self.controller reloadPlayerConfiguration];
    
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
        
        SRGMedia *updatedMedia = media ?: [mediaComposition mediaForSegment:mediaComposition.mainSegment ?: mediaComposition.mainChapter];
        NSString *updatedmediaURN = mediaURN ?: updatedMedia.URN;
        
        [self updateWithURN:updatedmediaURN media:updatedMedia mediaComposition:mediaComposition preferredQuality:preferredQuality];
        
        SRGRequest *playRequest = [self.controller playMediaComposition:mediaComposition withPreferredProtocol:SRGProtocolNone preferredQuality:preferredQuality userInfo:nil resume:NO completionHandler:^(NSError * _Nonnull error) {
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
    
    SRGMediaURN *srgMediaURN = [[SRGMediaURN alloc] initWithURN:mediaURN];
    if (!srgMediaURN) {
        NSError *error = [NSError errorWithDomain:SRGLetterboxErrorDomain
                                             code:SRGLetterboxErrorCodeNotFound
                                         userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The media cannot be played", nil) }];
        [self.requestQueue reportError:error];
        return;
    }
    
    SRGDataProvider *mediaCompositionDataProvider = [[SRGDataProvider alloc] initWithServiceURL:[SRGDataProvider defaultServiceURL]
                                                                         businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierForVendor(srgMediaURN.vendor)];
    
    if (srgMediaURN.mediaType == SRGMediaTypeVideo) {
        SRGRequest *mediaCompositionRequest = [mediaCompositionDataProvider mediaCompositionForVideoWithUid:srgMediaURN.uid completionBlock:mediaCompositionCompletionBlock];
        [self.requestQueue addRequest:mediaCompositionRequest resume:YES];
    }
    else if (srgMediaURN.mediaType == SRGMediaTypeAudio) {
        SRGRequest *mediaCompositionRequest = [mediaCompositionDataProvider mediaCompositionForAudioWithUid:srgMediaURN.uid completionBlock:mediaCompositionCompletionBlock];
        [self.requestQueue addRequest:mediaCompositionRequest resume:YES];
    }
}

- (void)resumeFromController:(SRGLetterboxController *)controller
{
    SRGMediaComposition *mediaComposition = controller.mediaComposition;
    NSAssert(controller.mediaComposition, @"Only playback operations with a media composition are allowed on SRGLetterboxController");
    
    SRGSegment *segment = mediaComposition.mainSegment ?: mediaComposition.mainChapter;
    SRGMedia *media = [mediaComposition mediaForSegment:segment];
    [self updateWithURN:media.URN media:media mediaComposition:mediaComposition preferredQuality:self.preferredQuality];
    
    self.controller = controller;
    
    // Perform media-dependent updates
    [self.controller reloadPlayerConfiguration];
}

- (void)reset
{
    [self updateWithURN:nil media:nil mediaComposition:nil preferredQuality:SRGQualityNone];
}

- (void)reportError:(NSError *)error
{
    if (! error) {
        return;
    }
    
    self.error = error;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxServicePlaybackDidFailNotification object:self];
}

#pragma mark Control center and lock screen integration

- (void)setupRemoteCommandCenter
{
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    MPRemoteCommand *playCommand = commandCenter.playCommand;
    [playCommand addTarget:self action:@selector(play:)];
    
    MPRemoteCommand *pauseCommand = commandCenter.pauseCommand;
    [pauseCommand addTarget:self action:@selector(pause:)];
    
    MPRemoteCommand *togglePlayPauseCommand = commandCenter.togglePlayPauseCommand;
    [togglePlayPauseCommand addTarget:self action:@selector(togglePlayPause:)];
    
    MPSkipIntervalCommand *skipForwardIntervalCommand = commandCenter.skipForwardCommand;
    skipForwardIntervalCommand.preferredIntervals = @[@(SRGLetterboxForwardSeekInterval)];
    [skipForwardIntervalCommand addTarget:self action:@selector(seekForward:)];
    
    MPSkipIntervalCommand *skipBackwardIntervalCommand = commandCenter.skipBackwardCommand;
    skipBackwardIntervalCommand.preferredIntervals = @[@(SRGLetterboxBackwardSeekInterval)];
    [skipBackwardIntervalCommand addTarget:self action:@selector(seekBackward:)];
}

- (void)updateRemoteCommandCenter
{
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    // Videos can only be controlled when the device has been locked (mostly for Airplay playback). We don't allow
    // video playback while the app is fully in background for the moment (except if Airplay is enabled)
    if (self.controller.playbackState != SRGMediaPlayerPlaybackStateIdle
            && (self.controller.mediaType == SRGMediaTypeAudio
                    || [UIApplication sharedApplication].applicationState != UIApplicationStateBackground
                    || [AVAudioSession srg_isAirplayActive]
                    || [UIDevice srg_isLocked])) {
        commandCenter.playCommand.enabled = YES;
        commandCenter.pauseCommand.enabled = YES;
        commandCenter.togglePlayPauseCommand.enabled = YES;
        commandCenter.skipForwardCommand.enabled = [self.controller canSeekForward];
        commandCenter.skipBackwardCommand.enabled = [self.controller canSeekBackward];
    }
    else {
        commandCenter.playCommand.enabled = NO;
        commandCenter.pauseCommand.enabled = NO;
        commandCenter.togglePlayPauseCommand.enabled = NO;
        commandCenter.skipForwardCommand.enabled = NO;
        commandCenter.skipBackwardCommand.enabled = NO;
    }
}

- (void)updateNowPlayingInformation
{
    NSMutableDictionary *nowPlayingInfo = [NSMutableDictionary dictionary];
    
    switch (self.media.mediaType) {
        case SRGMediaTypeAudio: {
            nowPlayingInfo[MPMediaItemPropertyMediaType] = @(MPMediaTypeAnyAudio);
            break;
        }
            
        case SRGMediaTypeVideo: {
            nowPlayingInfo[MPMediaItemPropertyMediaType] = @(MPMediaTypeAnyVideo);
            break;
        }
            
        default: {
            nowPlayingInfo[MPMediaItemPropertyMediaType] = @(MPMediaTypeAny);
            break;
        }
    }
    
    nowPlayingInfo[MPMediaItemPropertyTitle] = self.media.title;
    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = self.media.lead;
    
    NSURL *imageURL = [self.media imageURLForDimension:SRGImageDimensionWidth withValue:256.f * [UIScreen mainScreen].scale];
    self.imageOperation = [[YYWebImageManager sharedManager] requestImageWithURL:imageURL options:0 progress:nil transform:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
        if (image) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:image];
        }
        
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = [nowPlayingInfo copy];
    }];
    
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = [nowPlayingInfo copy];
}

// Playback information which requires more frequent updates
- (void)updateNowPlayingPlaybackInformation
{
    NSMutableDictionary *nowPlayingInfo = [[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo mutableCopy];
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(CMTimeGetSeconds(self.controller.player.currentTime));
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @(CMTimeGetSeconds(self.controller.player.currentItem.duration));
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = [nowPlayingInfo copy];
}

- (void)play:(id)sender
{
    [self.controller play];
}

- (void)pause:(id)sender
{
    [self.controller pause];
}

- (void)togglePlayPause:(id)sender
{
    [self.controller togglePlayPause];
}

- (void)seekForward:(id)sender
{
    [self.controller seekForwardWithCompletionHandler:nil];
}

- (void)seekBackward:(id)sender
{
    [self.controller seekBackwardWithCompletionHandler:nil];
}

#pragma mark AVPictureInPictureControllerDelegate protocol

- (void)pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController
{
    if ([self.delegate respondsToSelector:@selector(letterboxDidStartPictureInPicture)]) {
        [self.delegate letterboxDidStartPictureInPicture];
    }
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    // It is very important that the completion handler is called at the very end of the process, otherwise silly
    // things might happen during the restoration (most notably player rate set to 0)
    
    // If stopping picture in picture because of a reset, don't restore anything
    if (self.controller.playbackState == SRGMediaPlayerPlaybackStateIdle) {
        completionHandler(YES);
        return;
    }
    
    if ([self.delegate letterboxShouldRestoreUserInterfaceForPictureInPicture]) {
        [self.delegate letterboxRestoreUserInterfaceForPictureInPictureWithCompletionHandler:^(BOOL restored) {
            completionHandler(restored);
        }];
    }
    else {
        completionHandler(YES);
    }
}

- (void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController
{
    if ([self.delegate respondsToSelector:@selector(letterboxDidStopPictureInPicture)]) {
        [self.delegate letterboxDidStopPictureInPicture];
    }
    
    if ([self.delegate letterboxShouldRestoreUserInterfaceForPictureInPicture]) {
        // If switching from PiP to Airplay, restore the UI (just call the restoration method directly)
        if (self.controller.player.externalPlaybackActive) {
            [self pictureInPictureController:pictureInPictureController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:^(BOOL restored) {}];
        }
        else {
            [self.controller reset];
        }
    }
}

#pragma mark Notifications

- (void)playbackStateDidChange:(NSNotification *)notification
{
    if (self.controller.playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        [self updateNowPlayingInformation];
    }
}

- (void)playbackDidFail:(NSNotification *)notification
{
    [self reportError:notification.userInfo[SRGMediaPlayerErrorKey]];
}

- (void)audioSessionWasInterrupted:(NSNotification *)notification
{
    AVAudioSessionInterruptionType interruptionType = [notification.userInfo[AVAudioSessionInterruptionTypeKey] integerValue];
    AVAudioSessionInterruptionOptions interruptionOption = [notification.userInfo[AVAudioSessionInterruptionOptionKey] integerValue];
    
    // The system interrupted the audio session
    if (interruptionType == AVAudioSessionInterruptionTypeBegan) {
        if (self.controller.streamType == SRGMediaPlayerStreamTypeLive) {
            [self.controller stop];
        }
        else {
            [self.controller pause];
        }
    }
    // Interruption ended, resume if needed
    else if (interruptionType == AVAudioSessionInterruptionTypeEnded) {
        // Restart audio if suggested
        if (interruptionOption == AVAudioSessionInterruptionOptionShouldResume
                && self.controller.mediaType == SRGMediaPlayerMediaTypeAudio) {
            [self.controller play];
        }
    }
}

// Update commands while transitioning from / to the background (since control availability might be affected)
- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self updateRemoteCommandCenter];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self updateRemoteCommandCenter];
}

- (void)reachabilityDidChange:(NSNotification *)notification
{
    if ([FXReachability sharedInstance].reachable) {
        if (self.media) {
            [self playMedia:self.media withPreferredQuality:self.preferredQuality];
        }
    }
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; media: %@; mediaComposition: %@; error: %@>",
            [self class],
            self,
            self.media,
            self.mediaComposition,
            self.error];
}

@end
