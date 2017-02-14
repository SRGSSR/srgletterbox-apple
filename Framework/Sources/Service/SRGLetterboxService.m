//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxService.h"

#import "SRGLetterboxController+Private.h"
#import "UIDevice+SRGLetterbox.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <MediaPlayer/MediaPlayer.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <YYWebImage/YYWebImage.h>

NSString * const SRGLetterboxServiceSettingsDidChangeNotification = @"SRGLetterboxServiceSettingsDidChangeNotification";

@interface SRGLetterboxService () {
@private
    BOOL _restoreUserInterface;
    BOOL _playbackStopped;
    BOOL _disablingAudioServices;
}

@property (nonatomic) SRGLetterboxController *controller;
@property (nonatomic) id<SRGLetterboxPictureInPictureDelegate> pictureInPictureDelegate;

@property (nonatomic, weak) id periodicTimeObserver;
@property (nonatomic) YYWebImageOperation *imageOperation;

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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        [self setupRemoteCommandCenter];
        
        _restoreUserInterface = YES;
        _playbackStopped = YES;
    }
    return self;
}

- (void)dealloc
{
    self.controller = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Getters and setters

- (void)setController:(SRGLetterboxController *)controller
{
    if (_controller) {
        // Revert back to default behavior
        _controller.playerConfigurationBlock = nil;
        [_controller reloadPlayerConfiguration];
        
        SRGMediaPlayerController *previousMediaPlayerController = _controller.mediaPlayerController;
        previousMediaPlayerController.pictureInPictureController.delegate = nil;
        
        [previousMediaPlayerController removeObserver:self keyPath:@keypath(previousMediaPlayerController.pictureInPictureController.pictureInPictureActive)];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                      object:previousMediaPlayerController];
        
        [previousMediaPlayerController removePeriodicTimeObserver:self.periodicTimeObserver];
    }
    
    _controller = controller;
    
    [self updateRemoteCommandCenter];
    [self updateNowPlayingInformation];
    [self updateNowPlayingPlaybackInformation];
    
    if (controller) {
        controller.playerConfigurationBlock = ^(AVPlayer *player) {
            player.allowsExternalPlayback = YES;
            player.usesExternalPlaybackWhileExternalScreenIsActive = ! self.mirroredOnExternalScreen;
        };
        [controller reloadPlayerConfiguration];
        
        SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
        
        @weakify(self)
        @weakify(mediaPlayerController)
        [mediaPlayerController addObserver:self keyPath:@keypath(mediaPlayerController.pictureInPictureController.pictureInPictureActive) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            @strongify(mediaPlayerController)
            
            // When enabling Airplay from the control center while picture in picture is active, picture in picture will be
            // stopped without the usual restoration and stop delegate methods being called. KVO observe changes and call
            // those methods manually
            if (mediaPlayerController.player.externalPlaybackActive) {
                [self pictureInPictureController:mediaPlayerController.pictureInPictureController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:^(BOOL restored) {}];
                [self pictureInPictureControllerDidStopPictureInPicture:mediaPlayerController.pictureInPictureController];
            }
        }];
        
        if (mediaPlayerController.pictureInPictureController) {
            mediaPlayerController.pictureInPictureController.delegate = self;
        }
        else {
            @weakify(self)
            mediaPlayerController.pictureInPictureControllerCreationBlock = ^(AVPictureInPictureController *pictureInPictureController) {
                @strongify(self)
                
                pictureInPictureController.delegate = self;
            };
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateDidChange:)
                                                     name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                   object:mediaPlayerController];
        
        self.periodicTimeObserver = [mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
            [self updateNowPlayingPlaybackInformation];
            [self updateRemoteCommandCenter];
        }];
    }
}

- (void)setMirroredOnExternalScreen:(BOOL)mirroredOnExternalScreen
{
    if (_mirroredOnExternalScreen == mirroredOnExternalScreen) {
        return;
    }
    
    _mirroredOnExternalScreen = mirroredOnExternalScreen;
    [self.controller.mediaPlayerController reloadPlayerConfiguration];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxServiceSettingsDidChangeNotification object:self];
}

#pragma mark Enabling and disabling the service

- (void)enableWithController:(SRGLetterboxController *)controller pictureInPictureDelegate:(id<SRGLetterboxPictureInPictureDelegate>)pictureInPictureDelegate
{
    if (self.controller == controller && self.pictureInPictureDelegate == pictureInPictureDelegate) {
        return;
    }
    
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        NSArray<NSString *> *backgroundModes = [NSBundle mainBundle].infoDictionary[@"UIBackgroundModes"];
        if (! [backgroundModes containsObject:@"audio"]) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"You must enable the 'Audio, Airplay, and Picture in Picture' flag of your target background modes (under the Capabilities tab) before attempting to use the Letterbox service"
                                         userInfo:nil];
        }
    });
    
    self.controller = controller;
    self.pictureInPictureDelegate = pictureInPictureDelegate;
    
    _disablingAudioServices = NO;
    
    // Required for Airplay, picture in picture and control center to work correctly
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxServiceSettingsDidChangeNotification object:self];
}

- (void)disable
{
    if (! self.controller && ! self.pictureInPictureDelegate) {
        return;
    }
    
    self.controller = nil;
    self.pictureInPictureDelegate = nil;
    
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    
    // Cancel after some delay to let running audio processes gently terminate (otherwise audio hiccups will be
    // noticeable because of the audio session category change)
    _disablingAudioServices = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Since dispatch_after cannot be cancelled, deal with the possibility that services are enabled again while
        // the the block has not been executed yet
        if (! _disablingAudioServices) {
            return;
        }
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:nil];
    });
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxServiceSettingsDidChangeNotification object:self];
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
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    
    // Videos can only be controlled when the device has been locked (mostly for Airplay playback). We don't allow
    // video playback while the app is fully in background for the moment (except if Airplay is enabled)
    if (mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateIdle
            && (mediaPlayerController.mediaType == SRGMediaTypeAudio
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
    
    SRGMedia *media = self.controller.media;
    switch (media.mediaType) {
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
    
    nowPlayingInfo[MPMediaItemPropertyTitle] = media.title;
    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = media.lead;
    
    NSURL *imageURL = [media imageURLForDimension:SRGImageDimensionWidth withValue:256.f * [UIScreen mainScreen].scale];
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
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    NSMutableDictionary *nowPlayingInfo = [[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo mutableCopy];
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(CMTimeGetSeconds(mediaPlayerController.player.currentTime));
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @(CMTimeGetSeconds(mediaPlayerController.player.currentItem.duration));
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = [nowPlayingInfo copy];
}

- (void)play:(id)sender
{
    [self.controller.mediaPlayerController play];
}

- (void)pause:(id)sender
{
    [self.controller.mediaPlayerController pause];
}

- (void)togglePlayPause:(id)sender
{
    [self.controller.mediaPlayerController togglePlayPause];
}

- (void)seekForward:(id)sender
{
    [self.controller seekForwardWithCompletionHandler:nil];
}

- (void)seekBackward:(id)sender
{
    [self.controller seekBackwardWithCompletionHandler:nil];
}

#pragma mark Picture in picture

- (void)stopPictureInPictureRestoreUserInterface:(BOOL)restoreUserInterface
{
    AVPictureInPictureController *pictureInPictureController = self.controller.mediaPlayerController.pictureInPictureController;
    if (! pictureInPictureController.pictureInPictureActive) {
        return;
    }
    
    _restoreUserInterface = restoreUserInterface;
    [pictureInPictureController stopPictureInPicture];
}

#pragma mark AVPictureInPictureControllerDelegate protocol

- (void)pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController
{
    _restoreUserInterface = _restoreUserInterface && [self.pictureInPictureDelegate letterboxDismissUserInterfaceForPictureInPicture];
    
    if ([self.pictureInPictureDelegate respondsToSelector:@selector(letterboxDidStartPictureInPicture)]) {
        [self.pictureInPictureDelegate letterboxDidStartPictureInPicture];
    }
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    // If the restoration method gets called, this means playback was not stopped from the picture in picture stop button
    _playbackStopped = NO;
    
    if (! _restoreUserInterface) {
        completionHandler(YES);
        return;
    }
    
    // It is very important that the completion handler is called at the very end of the process, otherwise silly
    // things might happen during the restoration (most notably player rate set to 0)
    
    // If stopping picture in picture because of a reset, don't restore anything
    if (self.controller.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle) {
        completionHandler(YES);
        return;
    }
    
    if ([self.pictureInPictureDelegate letterboxShouldRestoreUserInterfaceForPictureInPicture]) {
        [self.pictureInPictureDelegate letterboxRestoreUserInterfaceForPictureInPictureWithCompletionHandler:^(BOOL restored) {
            completionHandler(restored);
        }];
    }
    else {
        completionHandler(YES);
    }
}

- (void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController
{
    if ([self.pictureInPictureDelegate respondsToSelector:@selector(letterboxDidEndPictureInPicture)]) {
        [self.pictureInPictureDelegate letterboxDidEndPictureInPicture];
    }
    
    if (_playbackStopped) {
        if ([self.pictureInPictureDelegate respondsToSelector:@selector(letterboxDidStopPlaybackFromPictureInPicture)]) {
            [self.pictureInPictureDelegate letterboxDidStopPlaybackFromPictureInPicture];
        }
    }
    
    // Reset to default values
    _playbackStopped = YES;
    _restoreUserInterface = YES;
}

#pragma mark Notifications

- (void)playbackStateDidChange:(NSNotification *)notification
{
    if (self.controller.mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePreparing) {
        [self updateNowPlayingInformation];
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

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; controller: %@; pictureInPictureDelegate: %@>",
            [self class],
            self,
            self.controller,
            self.pictureInPictureDelegate];
}

@end
