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

static void *s_kvoContext = &s_kvoContext;

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

__attribute__((constructor)) static void SRGLetterboxServiceInit(void)
{
    // Setup for Airplay, picture in picture and control center integration
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

@interface SRGLetterboxService ()

@property (nonatomic, weak) id periodicTimeObserver;

@property (nonatomic) SRGMediaURN *URN;
@property (nonatomic) SRGMedia *media;
@property (nonatomic) SRGMediaComposition *mediaComposition;
@property (nonatomic) SRGQuality preferredQuality;
@property (nonatomic) NSError *error;

@property (nonatomic) YYWebImageOperation *imageOperation;
@property (nonatomic) SRGRequestQueue *requestQueue;

@property (nonatomic, getter=isMirroredOnExternalScreen) BOOL mirroredOnExternalScreen;

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
        NSArray<NSString *> *backgroundModes = [NSBundle mainBundle].infoDictionary[@"UIBackgroundModes"];
        if (! [backgroundModes containsObject:@"audio"]) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"You must enable the 'Audio, Airplay, and Picture in Picture' flag of your target background modes (under the Capabilities tab) before attempting to use the Letterbox service"
                                         userInfo:nil];
        }
        
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
        
        [_controller removeObserver:self forKeyPath:@keypath(_controller.pictureInPictureController.pictureInPictureActive) context:s_kvoContext];
        
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
            // Allow external playback
            player.allowsExternalPlayback = YES;
            player.usesExternalPlaybackWhileExternalScreenIsActive = ! self.mirroredOnExternalScreen;
            
            // Only update the audio session if needed to avoid audio hiccups
            NSString *mode = (self.media.mediaType == SRGMediaTypeVideo) ? AVAudioSessionModeMoviePlayback : AVAudioSessionModeDefault;
            if (! [[AVAudioSession sharedInstance].mode isEqualToString:mode]) {
                [[AVAudioSession sharedInstance] setMode:mode error:NULL];
            }
        };
        
        [_controller addObserver:self forKeyPath:@keypath(_controller.pictureInPictureController.pictureInPictureActive) options:0 context:s_kvoContext];
        
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

- (void)setMirroredOnExternalScreen:(BOOL)mirroredOnExternalScreen
{
    if (_mirroredOnExternalScreen == mirroredOnExternalScreen) {
        return;
    }
    
    _mirroredOnExternalScreen = mirroredOnExternalScreen;
    [self.controller reloadPlayerConfiguration];
}

- (BOOL)isExternalScreenMirroringActive
{
    return [UIScreen srg_isMirroring] && ! self.controller.player.usesExternalPlaybackWhileExternalScreenIsActive;
}

#pragma mark Data

- (void)updateWithURN:(SRGMediaURN *)URN media:(SRGMedia *)media mediaComposition:(SRGMediaComposition *)mediaComposition preferredQuality:(SRGQuality)preferredQuality
{
    if (media) {
        URN = media.URN;
    }
    
    if ([self.URN isEqual:URN] && self.media == media && self.mediaComposition == mediaComposition) {
        return;
    }
    
    SRGMediaURN *previousURN = self.URN;
    SRGMedia *previousMedia = self.media;
    SRGMediaComposition *previousMediaComposition = self.mediaComposition;
    SRGQuality previousPreferredQuality = self.preferredQuality;
    
    self.URN = URN;
    self.media = media;
    self.mediaComposition = mediaComposition;
    self.preferredQuality = preferredQuality;
    
    if (! media || ! URN) {
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
    if (URN) {
        userInfo[SRGLetterboxServiceURNKey] = URN;
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
    if (self.controller.playbackState != SRGMediaPlayerPlaybackStateIdle && [self.media.URN isEqual:URN]) {
        return;
    }
    
    [self updateWithURN:URN media:media mediaComposition:nil preferredQuality:preferredQuality];
    
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
        SRGMediaURN *updatedURN = URN ?: updatedMedia.URN;
        
        [self updateWithURN:updatedURN media:updatedMedia mediaComposition:mediaComposition preferredQuality:preferredQuality];
        
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
        else if (self.URN) {
            [self playURN:self.URN withPreferredQuality:self.preferredQuality];
        }
    }
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (context == s_kvoContext) {
        if ([keyPath isEqualToString:@keypath(SRGLetterboxController.new, pictureInPictureController.pictureInPictureActive)]) {
            // When enabling Airplay from the control center while picture in picture is active, picture in picture will be
            // stopped without the usual restoration and stop delegate methods being called. KVO observe changes and call
            // those methods manually
            if (self.controller.player.externalPlaybackActive) {
                [self pictureInPictureController:self.controller.pictureInPictureController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:^(BOOL restored) {}];
                [self pictureInPictureControllerDidStopPictureInPicture:self.controller.pictureInPictureController];
            }
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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
