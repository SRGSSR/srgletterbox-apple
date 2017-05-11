//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxService.h"

#import "SRGLetterboxController+Private.h"
#import "UIDevice+SRGLetterbox.h"
#import "UIImage+SRGLetterbox.h"

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

@property (nonatomic) NSURL *currentArtworkImageURL;
@property (nonatomic) MPMediaItemArtwork *currentArtwork;

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
        [previousMediaPlayerController removeObserver:self keyPath:@keypath(previousMediaPlayerController.pictureInPictureController.pictureInPictureActive)];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGLetterboxMetadataDidChangeNotification
                                                      object:_controller];
        
        // Probably register for media metadata updates to reload the control center. Apply same logic as in Letterbox UIView
        // to display show info first
        
        [previousMediaPlayerController removePeriodicTimeObserver:self.periodicTimeObserver];
    }
    
    _controller = controller;
    
    [self updateRemoteCommandCenterWithController:controller];
    [self updateNowPlayingInformationWithController:controller];
    
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
                                                 selector:@selector(metadataDidChange:)
                                                     name:SRGLetterboxMetadataDidChangeNotification
                                                   object:controller];
        
        self.periodicTimeObserver = [mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
            [self updateNowPlayingInformationWithController:controller];
            [self updateRemoteCommandCenterWithController:controller];
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
    self.pictureInPictureDelegate = [AVPictureInPictureController isPictureInPictureSupported] ? pictureInPictureDelegate : nil;
    
    _disablingAudioServices = NO;
    
    // Required for Airplay, picture in picture and control center to work correctly
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxServiceSettingsDidChangeNotification object:self];
}

- (void)disableForController:(SRGLetterboxController *)controller
{
    if (self.controller != controller) {
        return;
    }
    
    [self disable];
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
    skipForwardIntervalCommand.preferredIntervals = @[@(SRGLetterboxForwardSkipInterval)];
    [skipForwardIntervalCommand addTarget:self action:@selector(skipForward:)];
    
    MPSkipIntervalCommand *skipBackwardIntervalCommand = commandCenter.skipBackwardCommand;
    skipBackwardIntervalCommand.preferredIntervals = @[@(SRGLetterboxBackwardSkipInterval)];
    [skipBackwardIntervalCommand addTarget:self action:@selector(skipBackward:)];
    
    MPRemoteCommand *seekForwardCommand = commandCenter.seekForwardCommand;
    [seekForwardCommand addTarget:self action:@selector(seekForward:)];
    
    MPRemoteCommand *seekBackwardCommand = commandCenter.seekBackwardCommand;
    [seekBackwardCommand addTarget:self action:@selector(seekBackward:)];
    
    MPRemoteCommand *previousTrackCommand = commandCenter.previousTrackCommand;
    [previousTrackCommand addTarget:self action:@selector(previousTrack:)];
    
    MPRemoteCommand *nextTrackCommand = commandCenter.nextTrackCommand;
    [nextTrackCommand addTarget:self action:@selector(nextTrack:)];
}

- (void)updateRemoteCommandCenterWithController:(SRGLetterboxController *)controller
{
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
    
    // Videos can only be controlled when the device has been locked (mostly for Airplay playback). We don't allow
    // video playback while the app is fully in background for the moment (except if Airplay is enabled)
    if (mediaPlayerController && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateIdle && (mediaPlayerController.mediaType == SRGMediaTypeAudio
                                                                                                            || [UIApplication sharedApplication].applicationState != UIApplicationStateBackground
                                                                                                            || [AVAudioSession srg_isAirplayActive]
                                                                                                            || [UIDevice srg_isLocked])) {
        SRGLetterboxCommands availableCommands = SRGLetterboxCommandSkipForward | SRGLetterboxCommandSkipBackward | SRGLetterboxCommandSeekForward | SRGLetterboxCommandSeekBackward;
        if (self.commandDelegate) {
            availableCommands = [self.commandDelegate letterboxAvailableCommands];
        }
        
        commandCenter.playCommand.enabled = YES;
        commandCenter.pauseCommand.enabled = YES;
        commandCenter.togglePlayPauseCommand.enabled = YES;
        commandCenter.skipForwardCommand.enabled = (availableCommands & SRGLetterboxCommandSkipForward) && [controller canSkipForward];
        commandCenter.skipBackwardCommand.enabled = (availableCommands & SRGLetterboxCommandSkipBackward) && [controller canSkipBackward];
        commandCenter.seekForwardCommand.enabled = (availableCommands & SRGLetterboxCommandSeekForward);
        commandCenter.seekBackwardCommand.enabled = (availableCommands & SRGLetterboxCommandSeekBackward);
        commandCenter.nextTrackCommand.enabled = (availableCommands & SRGLetterboxCommandNextTrack);
        commandCenter.previousTrackCommand.enabled = (availableCommands & SRGLetterboxCommandPreviousTrack);
    }
    else {
        commandCenter.playCommand.enabled = NO;
        commandCenter.pauseCommand.enabled = NO;
        commandCenter.togglePlayPauseCommand.enabled = NO;
        commandCenter.skipForwardCommand.enabled = NO;
        commandCenter.skipBackwardCommand.enabled = NO;
        commandCenter.seekForwardCommand.enabled = NO;
        commandCenter.seekBackwardCommand.enabled = NO;
        commandCenter.nextTrackCommand.enabled = NO;
        commandCenter.previousTrackCommand.enabled = NO;
    }
}

- (void)updateNowPlayingInformationWithController:(SRGLetterboxController *)controller
{
    SRGMedia *media = controller.segmentMedia ?: controller.fullLengthMedia ?: controller.media;
    if (! media) {
        self.currentArtworkImageURL = nil;
        self.currentArtwork = nil;
        
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;
        return;
    }
    
    NSMutableDictionary *nowPlayingInfo = [NSMutableDictionary dictionary];
    
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
    
    NSURL *artworkImageURL = nil;
    
    CGFloat artworkDimension = 512.f * [UIScreen mainScreen].scale;
    
    // For livestreams, only rely on channel information
    if (media.contentType == SRGContentTypeLivestream) {
        SRGChannel *channel = controller.channel;
        
        // Display program information (if any) when the controller position is within the current program, otherwise channel
        // information.
        NSDate *playbackDate = [NSDate dateWithTimeIntervalSinceNow:-CMTimeGetSeconds(CMTimeSubtract(CMTimeRangeGetEnd(controller.timeRange), controller.currentTime))];
        if (channel.currentProgram
                && [channel.currentProgram.startDate compare:playbackDate] != NSOrderedDescending
                && [playbackDate compare:channel.currentProgram.endDate] != NSOrderedDescending) {
            NSString *title = channel.currentProgram.title;
            nowPlayingInfo[MPMediaItemPropertyTitle] = title;
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = ! [channel.title isEqualToString:title] ? channel.title : nil;
            
            artworkImageURL = SRGLetterboxArtworkImageURL(channel.currentProgram, artworkDimension);
            if (! artworkImageURL) {
                artworkImageURL = SRGLetterboxArtworkImageURL(channel, artworkDimension);
            }
        }
        else {
            nowPlayingInfo[MPMediaItemPropertyTitle] = channel.title;
            
            artworkImageURL = SRGLetterboxArtworkImageURL(channel, artworkDimension);
        }
    }
    else {
        nowPlayingInfo[MPMediaItemPropertyTitle] = media.title;
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = media.show.title;
        artworkImageURL = SRGLetterboxArtworkImageURL(media, artworkDimension);
    }
    
    if (! [artworkImageURL isEqual:self.currentArtworkImageURL] || ! self.currentArtwork) {
        self.currentArtwork = nil;
        
        // SRGLetterboxImageURL might return file URLs for overridden images
        if (artworkImageURL.fileURL) {
            UIImage *image = [UIImage imageWithContentsOfFile:artworkImageURL.path];
            MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork;
            self.currentArtworkImageURL = artworkImageURL;
            self.currentArtwork = artwork;
        }
        else if (artworkImageURL) {
            // Use Cloudinary to create square artwork images (SRG SSR image services do not support such use cases).
            // FIXME: This arbitrary resizing could be moved to the data provider library
            NSString *URLString = [NSString stringWithFormat:@"https://srgssr-prod.apigee.net/image-play-scale-2/image/fetch/w_%.0f,h_%.0f,c_pad,b_black/%@", artworkDimension, artworkDimension, artworkImageURL.absoluteString];
            NSURL *cloudinaryURL = [NSURL URLWithString:URLString];
            self.imageOperation = [[YYWebImageManager sharedManager] requestImageWithURL:cloudinaryURL options:0 progress:nil transform:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (! image) {
                        return;
                    }
                    
                    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork;
                    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = [nowPlayingInfo copy];
                    self.currentArtworkImageURL = artworkImageURL;
                    self.currentArtwork = artwork;
                });
            }];
        }
        else {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = nil;
        }
    }
    else {
        nowPlayingInfo[MPMediaItemPropertyArtwork] = self.currentArtwork;
    }
    
    SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
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

- (void)skipForward:(id)sender
{
    [self.controller skipForwardWithCompletionHandler:nil];
}

- (void)skipBackward:(id)sender
{
    [self.controller skipBackwardWithCompletionHandler:nil];
}

- (void)seekForward:(MPSeekCommandEvent *)event
{
    if (event.type == MPSeekCommandEventTypeBeginSeeking) {
        [self.controller skipForwardWithCompletionHandler:nil];
    }
}

- (void)seekBackward:(MPSeekCommandEvent *)event
{
    if (event.type == MPSeekCommandEventTypeBeginSeeking) {
        [self.controller skipBackwardWithCompletionHandler:nil];
    }
}

- (void)previousTrack:(id)sender
{
    if ([self.commandDelegate respondsToSelector:@selector(letterboxWillSkipToPreviousTrack)]) {
        [self.commandDelegate letterboxWillSkipToPreviousTrack];
    }
}

- (void)nextTrack:(id)sender
{
    if ([self.commandDelegate respondsToSelector:@selector(letterboxWillSkipToNextTrack)]) {
        [self.commandDelegate letterboxWillSkipToNextTrack];
    }
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
    BOOL dismissed = [self.pictureInPictureDelegate letterboxDismissUserInterfaceForPictureInPicture];
    _restoreUserInterface = _restoreUserInterface && dismissed;
    
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

- (void)metadataDidChange:(NSNotification *)notification
{
    [self updateNowPlayingInformationWithController:self.controller];
}

// Update commands while transitioning from / to the background (since control availability might be affected)
- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self updateRemoteCommandCenterWithController:self.controller];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self updateRemoteCommandCenterWithController:self.controller];
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
