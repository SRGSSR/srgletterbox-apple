//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaService.h"

#import "UIDevice+SRGLetterbox.h"

#import <libextobjc/libextobjc.h>
#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>
#import <YYWebImage/YYWebImage.h>

NSString * const SRGMediaServiceMetadataDidChangeNotification = @"SRGMediaServiceMetadataDidChangeNotification";

NSString * const SRGMediaServiceMediaKey = @"SRGMediaServiceMediaKey";
NSString * const SRGMediaServiceMediaCompositionKey = @"SRGMediaServiceMediaCompositionKey";

NSString * const SRGMediaServicePreviousMediaKey = @"SRGMediaServicePreviousMediaKey";
NSString * const SRGMediaServicePreviousMediaCompositionKey = @"SRGMediaServicePreviousMediaCompositionKey";

NSString * const SRGMediaServicePlaybackDidFailNotification = @"SRGMediaServicePlaybackDidFailNotification";

@interface SRGMediaService ()

@property (nonatomic, weak) id periodicTimeObserver;

@property (nonatomic) SRGMedia *media;
@property (nonatomic) SRGMediaComposition *mediaComposition;
@property (nonatomic) NSError *error;

@property (nonatomic) YYWebImageOperation *imageOperation;
@property (nonatomic) SRGRequestQueue *requestQueue;

@end

@implementation SRGMediaService

#pragma mark Class methods

+ (SRGMediaService *)sharedSRGMediaService
{
    static SRGMediaService *s_SRGMediaService;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_SRGMediaService = [SRGMediaService new];
    });
    return s_SRGMediaService;
}

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
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

- (void)updateWithMedia:(SRGMedia *)media mediaComposition:(SRGMediaComposition *)mediaComposition
{
    SRGMedia *previousMedia = self.media;
    SRGMediaComposition *previousMediaComposition = self.mediaComposition;
    
    self.media = media;
    self.mediaComposition = mediaComposition;
    
    NSMutableDictionary<NSString *, id> *userInfo = [NSMutableDictionary dictionary];
    if (media) {
        userInfo[SRGMediaServiceMediaKey] = media;
    }
    if (mediaComposition) {
        userInfo[SRGMediaServiceMediaCompositionKey] = mediaComposition;
    }
    if (previousMedia) {
        userInfo[SRGMediaServicePreviousMediaKey] = previousMedia;
    }
    if (previousMediaComposition) {
        userInfo[SRGMediaServicePreviousMediaCompositionKey] = previousMediaComposition;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGMediaServiceMetadataDidChangeNotification object:self userInfo:[userInfo copy]];
}

#pragma mark Playback

- (void)playMedia:(SRGMedia *)media preferredQuality:(SRGQuality)quality
{
    // If already playing the media, does nothing
    if (self.controller.playbackState != SRGMediaPlayerPlaybackStateIdle
            && [self.media.uid isEqualToString:media.uid]) {
        return;
    }
    
    [self reset];
    [self updateWithMedia:media mediaComposition:nil];
    
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
        
        [self updateWithMedia:media mediaComposition:mediaComposition];
        
        SRGRequest *playRequest = [self.controller playMediaComposition:mediaComposition withPreferredProtocol:SRGProtocolNone preferredQuality:quality userInfo:nil resume:NO completionHandler:^(NSError * _Nonnull error) {
            [self.requestQueue reportError:error];
        }];
        
        if (playRequest) {
            [self.requestQueue addRequest:playRequest resume:YES];
        }
        else {
            NSError *error = [NSError errorWithDomain:@"ch.srgssr.letterbox" code:42 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"The media cannot be played", nil)}];
            [self.requestQueue reportError:error];
        }
    };
    
    if (self.media.mediaType == SRGMediaTypeVideo) {
        SRGRequest *mediaCompositionRequest = [[SRGDataProvider currentDataProvider] mediaCompositionForVideoWithUid:media.uid completionBlock:mediaCompositionCompletionBlock];
        [self.requestQueue addRequest:mediaCompositionRequest resume:YES];
    }
    else if (self.media.mediaType == SRGMediaTypeAudio) {
        SRGRequest *mediaCompositionRequest = [[SRGDataProvider currentDataProvider] mediaCompositionForAudioWithUid:media.uid completionBlock:mediaCompositionCompletionBlock];
        [self.requestQueue addRequest:mediaCompositionRequest resume:YES];
    }
}

- (BOOL)resumeFromSRGLetterboxController:(SRGLetterboxController *)controller
{
    SRGMediaComposition *mediaComposition = controller.mediaComposition;
    if (mediaComposition) {
        SRGSegment *segment = mediaComposition.mainSegment ?: mediaComposition.mainChapter;
        SRGMedia *media = [mediaComposition mediaForSegment:segment];
        [self updateWithMedia:media mediaComposition:mediaComposition];
    }
    // FIXME: Quick & dirty implementation. See MediaPlayerPreviewViewController.m
    else {
        SRGMedia *media = controller.userInfo[@"media"];
        if (media) {
            [self updateWithMedia:media mediaComposition:nil];
        }
        else {
            return NO;
        }
    }
    
    self.controller = controller;
    
    // Perform media-dependent updates
    [self.controller reloadPlayerConfiguration];
    
    return YES;
}

- (void)reset
{
    self.media = nil;
    self.mediaComposition = nil;
    self.error = nil;
    
    [self.controller reset];
    [self.requestQueue cancel];
    [self.imageOperation cancel];
    
    [self updateRemoteCommandCenter];
    [self updateNowPlayingInformation];
    [self updateNowPlayingPlaybackInformation];
}

- (void)reportError:(NSError *)error
{
    if (! error) {
        return;
    }
    
    self.error = error;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGMediaServicePlaybackDidFailNotification object:self];
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

#pragma mark Notifications

- (void)playbackStateDidChange:(NSNotification *)notification
{
    if (self.controller.playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        [self updateNowPlayingInformation];
    }
    else if (self.controller.playbackState == SRGMediaPlayerPlaybackStateIdle) {
        [self reset];
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

@end
