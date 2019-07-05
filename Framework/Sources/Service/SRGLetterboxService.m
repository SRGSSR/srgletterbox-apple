//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxService.h"

#import "MPRemoteCommand+SRGLetterbox.h"
#import "SRGLetterboxController+Private.h"
#import "SRGProgram+SRGLetterbox.h"
#import "UIDevice+SRGLetterbox.h"
#import "UIImage+SRGLetterbox.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <MediaPlayer/MediaPlayer.h>
#import <SRGAppearance/SRGAppearance.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <YYWebImage/YYWebImage.h>

SRGLetterboxCommands SRGLetterboxCommandsDefault = SRGLetterboxCommandSkipForward | SRGLetterboxCommandSkipBackward | SRGLetterboxCommandSeekForward | SRGLetterboxCommandSeekBackward;

NSString * const SRGLetterboxServiceSettingsDidChangeNotification = @"SRGLetterboxServiceSettingsDidChangeNotification";

@interface SRGLetterboxService () {
@private
    BOOL _restoreUserInterface;
    BOOL _playbackStopped;
    BOOL _disablingAudioServices;
}

@property (nonatomic) SRGLetterboxController *controller;
@property (nonatomic) id<SRGLetterboxPictureInPictureDelegate> pictureInPictureDelegate;

@property (nonatomic, getter=areNowPlayingInfoAndCommandsEnabled) BOOL nowPlayingInfoAndCommandsEnabled;
@property (nonatomic) SRGLetterboxCommands allowedCommands;

@property (nonatomic, weak) id periodicTimeObserver;
@property (nonatomic) YYWebImageOperation *imageOperation;

@property (atomic) NSURL *cachedArtworkURL;
@property (atomic) UIImage *cachedArtworkImage;

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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    if (self = [super init]) {
        self.nowPlayingInfoAndCommandsEnabled = YES;
        self.allowedCommands = SRGLetterboxCommandsDefault;
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(applicationDidEnterBackground:)
                                                   name:UIApplicationDidEnterBackgroundNotification
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(applicationDidBecomeActive:)
                                                   name:UIApplicationDidBecomeActiveNotification
                                                 object:nil];
        
        _restoreUserInterface = YES;
        _playbackStopped = YES;
    }
    return self;
}

#pragma clang diagnostic pop

- (void)dealloc
{
    self.controller = nil;
    self.nowPlayingInfoAndCommandsEnabled = NO;
}

#pragma mark Getters and setters

- (void)setNowPlayingInfoAndCommandsEnabled:(BOOL)nowPlayingInfoAndCommandsEnabled
{
    _nowPlayingInfoAndCommandsEnabled = nowPlayingInfoAndCommandsEnabled;
    
    if (nowPlayingInfoAndCommandsEnabled) {
        [self setupRemoteCommandCenter];
    }
    else {
        [self resetRemoteCommandCenter];
        MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = nil;
    }
}

- (void)setAllowedCommands:(SRGLetterboxCommands)allowedCommands
{
    _allowedCommands = allowedCommands;
    
    [self updateRemoteCommandCenterWithController:self.controller];
}

- (void)setController:(SRGLetterboxController *)controller
{
    if (_controller) {
        // Revert back to default behavior
        _controller.playerConfigurationBlock = nil;
        [_controller reloadPlayerConfiguration];
        
        SRGMediaPlayerController *previousMediaPlayerController = _controller.mediaPlayerController;
        AVPictureInPictureController *pictureInPictureController = previousMediaPlayerController.pictureInPictureController;
        [pictureInPictureController removeObserver:self keyPath:@keypath(pictureInPictureController.pictureInPictureActive)];
        
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGLetterboxMetadataDidChangeNotification
                                                    object:_controller];
        
        [previousMediaPlayerController removePeriodicTimeObserver:self.periodicTimeObserver];
    }
    
    _controller = controller;
    
    [self updateRemoteCommandCenterWithController:controller];
    [self updateNowPlayingInformationWithController:controller];
    
    if (controller) {
        controller.playerConfigurationBlock = ^(AVPlayer *player) {
            // Do not switch to external playback when playing anything other than videos. External playback is namely only
            // intended for video playback. If you try to play audio with external playback, then:
            //   - The screen will be black instead of displaying a media notification.
            //   - The user won't be able to change the volume with the phone controls.
            // Remark: For video external playback, it is normal that the user cannot control the volume from her device.
            player.allowsExternalPlayback = (controller.media.mediaType == SRGMediaTypeVideo);
            player.usesExternalPlaybackWhileExternalScreenIsActive = ! self.mirroredOnExternalScreen;
        };
        [controller reloadPlayerConfiguration];
        
        SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
        AVPictureInPictureController *pictureInPictureController = mediaPlayerController.pictureInPictureController;
        
        if (pictureInPictureController) {
            @weakify(self)
            @weakify(pictureInPictureController)
            [pictureInPictureController addObserver:self keyPath:@keypath(pictureInPictureController.pictureInPictureActive) options:0 block:^(MAKVONotification *notification) {
                @strongify(self)
                @strongify(pictureInPictureController)
                
                // When enabling AirPlay from the control center while picture in picture is active, picture in picture will be
                // stopped without the usual restoration and stop delegate methods being called. KVO observe changes and call
                // those methods manually
                if (mediaPlayerController.player.externalPlaybackActive) {
                    [self pictureInPictureController:pictureInPictureController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:^(BOOL restored) {}];
                    [self pictureInPictureControllerDidStopPictureInPicture:pictureInPictureController];
                }
            }];
            
            pictureInPictureController.delegate = self;
        }
        else {
            @weakify(self)
            mediaPlayerController.pictureInPictureControllerCreationBlock = ^(AVPictureInPictureController *pictureInPictureController) {
                @strongify(self)
                
                pictureInPictureController.delegate = self;
            };
        }
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(metadataDidChange:)
                                                   name:SRGLetterboxMetadataDidChangeNotification
                                                 object:controller];
        
        @weakify(self)
        self.periodicTimeObserver = [mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
            @strongify(self)
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
    
    [NSNotificationCenter.defaultCenter postNotificationName:SRGLetterboxServiceSettingsDidChangeNotification object:self];
}

#pragma mark Enabling and disabling the service

- (void)enableWithController:(SRGLetterboxController *)controller pictureInPictureDelegate:(id<SRGLetterboxPictureInPictureDelegate>)pictureInPictureDelegate
{
    if (self.controller == controller && self.pictureInPictureDelegate == pictureInPictureDelegate) {
        return;
    }
    
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        NSArray<NSString *> *backgroundModes = NSBundle.mainBundle.infoDictionary[@"UIBackgroundModes"];
        if (! [backgroundModes containsObject:@"audio"]) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"You must enable the 'Audio, AirPlay, and Picture in Picture' flag of your target background modes (under the Capabilities tab) before attempting to use the Letterbox service"
                                         userInfo:nil];
        }
    });
    
    self.controller = controller;
    self.pictureInPictureDelegate = [AVPictureInPictureController isPictureInPictureSupported] ? pictureInPictureDelegate : nil;
    
    _disablingAudioServices = NO;
    
    // Required for AirPlay, picture in picture and control center to work correctly
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];
    
    [NSNotificationCenter.defaultCenter postNotificationName:SRGLetterboxServiceSettingsDidChangeNotification object:self];
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
    
    // Cancel after some delay to let running audio processes gently terminate (otherwise audio hiccups will be
    // noticeable because of the audio session category change)
    _disablingAudioServices = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Since dispatch_after cannot be cancelled, deal with the possibility that services are enabled again while
        // the the block has not been executed yet
        if (! self->_disablingAudioServices) {
            return;
        }
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:NULL];
    });
    
    [NSNotificationCenter.defaultCenter postNotificationName:SRGLetterboxServiceSettingsDidChangeNotification object:self];
}

#pragma mark Control center and lock screen integration

- (void)setupRemoteCommandCenter
{
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    MPRemoteCommand *playCommand = commandCenter.playCommand;
    playCommand.enabled = NO;
    [playCommand srg_addUniqueTarget:self action:@selector(play:)];
    
    MPRemoteCommand *pauseCommand = commandCenter.pauseCommand;
    pauseCommand.enabled = NO;
    [pauseCommand srg_addUniqueTarget:self action:@selector(pause:)];
    
    MPRemoteCommand *togglePlayPauseCommand = commandCenter.togglePlayPauseCommand;
    togglePlayPauseCommand.enabled = NO;
    [togglePlayPauseCommand srg_addUniqueTarget:self action:@selector(togglePlayPause:)];
    
    MPSkipIntervalCommand *skipForwardIntervalCommand = commandCenter.skipForwardCommand;
    skipForwardIntervalCommand.enabled = NO;
    skipForwardIntervalCommand.preferredIntervals = @[@(SRGLetterboxForwardSkipInterval)];
    [skipForwardIntervalCommand srg_addUniqueTarget:self action:@selector(skipForward:)];
    
    MPSkipIntervalCommand *skipBackwardIntervalCommand = commandCenter.skipBackwardCommand;
    skipBackwardIntervalCommand.enabled = NO;
    skipBackwardIntervalCommand.preferredIntervals = @[@(SRGLetterboxBackwardSkipInterval)];
    [skipBackwardIntervalCommand srg_addUniqueTarget:self action:@selector(skipBackward:)];
    
    MPRemoteCommand *seekForwardCommand = commandCenter.seekForwardCommand;
    seekForwardCommand.enabled = NO;
    [seekForwardCommand srg_addUniqueTarget:self action:@selector(seekForward:)];
    
    MPRemoteCommand *seekBackwardCommand = commandCenter.seekBackwardCommand;
    seekBackwardCommand.enabled = NO;
    [seekBackwardCommand srg_addUniqueTarget:self action:@selector(seekBackward:)];
    
    MPRemoteCommand *previousTrackCommand = commandCenter.previousTrackCommand;
    previousTrackCommand.enabled = NO;
    [previousTrackCommand srg_addUniqueTarget:self action:@selector(previousTrack:)];
    
    MPRemoteCommand *nextTrackCommand = commandCenter.nextTrackCommand;
    nextTrackCommand.enabled = NO;
    [nextTrackCommand srg_addUniqueTarget:self action:@selector(nextTrack:)];
}

- (void)resetRemoteCommandCenter
{
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    // For some unknown reason, at least an action (even dummy) must be bound to a command for `enabled` to have an effect,
    // see https://stackoverflow.com/questions/38993801/how-to-disable-all-the-mpremotecommand-objects-from-mpremotecommandcenter
    
    MPRemoteCommand *playCommand = commandCenter.playCommand;
    playCommand.enabled = NO;
    [playCommand srg_addUniqueTarget:self action:@selector(doNothing:)];
    
    MPRemoteCommand *pauseCommand = commandCenter.pauseCommand;
    pauseCommand.enabled = NO;
    [pauseCommand srg_addUniqueTarget:self action:@selector(doNothing:)];
    
    MPRemoteCommand *togglePlayPauseCommand = commandCenter.togglePlayPauseCommand;
    togglePlayPauseCommand.enabled = NO;
    [togglePlayPauseCommand srg_addUniqueTarget:self action:@selector(doNothing:)];
    
    MPSkipIntervalCommand *skipForwardIntervalCommand = commandCenter.skipForwardCommand;
    skipForwardIntervalCommand.enabled = NO;
    skipForwardIntervalCommand.preferredIntervals = @[];
    [skipForwardIntervalCommand srg_addUniqueTarget:self action:@selector(doNothing:)];
    
    MPSkipIntervalCommand *skipBackwardIntervalCommand = commandCenter.skipBackwardCommand;
    skipBackwardIntervalCommand.enabled = NO;
    skipBackwardIntervalCommand.preferredIntervals = @[];
    [skipBackwardIntervalCommand srg_addUniqueTarget:self action:@selector(doNothing:)];
    
    MPRemoteCommand *seekForwardCommand = commandCenter.seekForwardCommand;
    seekForwardCommand.enabled = NO;
    [seekForwardCommand srg_addUniqueTarget:self action:@selector(doNothing:)];
    
    MPRemoteCommand *seekBackwardCommand = commandCenter.seekBackwardCommand;
    seekBackwardCommand.enabled = NO;
    [seekBackwardCommand srg_addUniqueTarget:self action:@selector(doNothing:)];
    
    MPRemoteCommand *previousTrackCommand = commandCenter.previousTrackCommand;
    previousTrackCommand.enabled = NO;
    [previousTrackCommand srg_addUniqueTarget:self action:@selector(doNothing:)];
    
    MPRemoteCommand *nextTrackCommand = commandCenter.nextTrackCommand;
    nextTrackCommand.enabled = NO;
    [nextTrackCommand srg_addUniqueTarget:self action:@selector(doNothing:)];
}

- (void)updateRemoteCommandCenterWithController:(SRGLetterboxController *)controller
{
    if (! self.nowPlayingInfoAndCommandsEnabled) {
        return;
    }
    
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
    
    if (mediaPlayerController && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateIdle && (mediaPlayerController.mediaType == SRGMediaTypeAudio
                                                                                                            || controller.backgroundVideoPlaybackEnabled
                                                                                                            || [UIApplication sharedApplication].applicationState != UIApplicationStateBackground
                                                                                                            || AVAudioSession.srg_isAirPlayActive
                                                                                                            || UIDevice.srg_letterbox_isLocked)) {
        commandCenter.playCommand.enabled = YES;
        commandCenter.pauseCommand.enabled = YES;
        commandCenter.togglePlayPauseCommand.enabled = YES;
        commandCenter.skipForwardCommand.enabled = (self.allowedCommands & SRGLetterboxCommandSkipForward) && [controller canSkipForward];
        commandCenter.skipBackwardCommand.enabled = (self.allowedCommands & SRGLetterboxCommandSkipBackward) && [controller canSkipBackward];
        commandCenter.seekForwardCommand.enabled = (self.allowedCommands & SRGLetterboxCommandSeekForward);
        commandCenter.seekBackwardCommand.enabled = (self.allowedCommands & SRGLetterboxCommandSeekBackward);
        commandCenter.nextTrackCommand.enabled = (self.allowedCommands & SRGLetterboxCommandNextTrack) && [controller canPlayNextMedia];
        commandCenter.previousTrackCommand.enabled = (self.allowedCommands & SRGLetterboxCommandPreviousTrack) && [controller canPlayPreviousMedia];
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

- (SRGMedia *)nowPlayingMediaForController:(SRGLetterboxController *)controller
{
    if (controller.media.mediaType == SRGMediaTypeVideo) {
        return controller.subdivisionMedia ?: controller.fullLengthMedia ?: controller.media;
    }
    else {
        return controller.media;
    }
}

- (void)updateNowPlayingInformationWithController:(SRGLetterboxController *)controller
{
    if (! self.nowPlayingInfoAndCommandsEnabled) {
        return;
    }
    
    SRGMedia *media = [self nowPlayingMediaForController:controller];
    if (! media) {
        [self clearArtworkImageCache];
        MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = nil;
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
    
    // Display channel information when available for a livestream (channel information alone does not suffice since
    // it can also be available for on-demand medias).
    SRGChannel *channel = controller.channel;
    if (media.contentType == SRGContentTypeLivestream && channel) {
        // Display program information (if any) when the controller position is within the current program, otherwise channel
        // information.
        NSDate *playbackDate = controller.date;
        if (playbackDate && [channel.currentProgram srgletterbox_containsDate:playbackDate]) {
            NSString *title = channel.currentProgram.title;
            nowPlayingInfo[MPMediaItemPropertyTitle] = title;
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = ! [channel.title isEqualToString:title] ? channel.title : @"";
        }
        else {
            nowPlayingInfo[MPMediaItemPropertyTitle] = channel.title;
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = @"";
        }
    }
    else {
        nowPlayingInfo[MPMediaItemPropertyTitle] = media.title;
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = media.show.title;
    }
    
    nowPlayingInfo[MPMediaItemPropertyArtist] = @"";
    
    CGFloat artworkDimension = 256.f * UIScreen.mainScreen.scale;
    CGSize maximumSize = CGSizeMake(artworkDimension, artworkDimension);
    
    // TODO: Remove when iOS 10 is the minimum supported version
    if (@available(iOS 10, *)) {
        // Home artwork retrieval works (because poorly documented):
        // Images are retrieved when needed by the now playing info center by calling -[MPMediaItemArtwork imageWithSize:]`. Sizes
        // larger than the bounds size specified at creation will be fixed to the maximum compatible value. The request block itself
        // must be implemented to return an image of the size it receives as parameter, and is called on a background thread.
        //
        // Moreover, a subtle issue might arise if the controller is strongly captured by the block (successive now playing information
        // center updates might deadlock).
        @weakify(controller)
        nowPlayingInfo[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithBoundsSize:maximumSize requestHandler:^UIImage * _Nonnull(CGSize size) {
            @strongify(controller);
            return [self cachedArtworkImageForController:controller withSize:size];
        }];
    }
    else {
        UIImage *artworkImage = [self cachedArtworkImageForController:controller withSize:maximumSize];
        nowPlayingInfo[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:artworkImage];
    }
    
    SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
    
    CMTimeRange timeRange = mediaPlayerController.timeRange;
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(CMTimeGetSeconds(CMTimeSubtract(mediaPlayerController.currentTime, timeRange.start)));
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @(CMTimeGetSeconds(timeRange.duration));
    
    // Available starting with iOS 10. When this property is set to YES the playback button is a play / stop button
    // on iOS 10, a play / pause button on iOS 11 and above, and LIVE is displayed instead of time progress.
    // TODO: Remove when the minimum required version is iOS 10
    if (@available(iOS 10, *)) {
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = @(mediaPlayerController.isLive);
    }
    
    MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = [nowPlayingInfo copy];
}

- (NSURL *)artworkURLForController:(SRGLetterboxController *)controller withSize:(CGSize)size
{
    CGFloat smallestDimension = fmin(size.width, size.height);
    NSURL *artworkURL = nil;
    
    // Display channel information when available for a livestream (channel information alone does not suffice since
    // it can also be available for on-demand medias).
    SRGMedia *media = [self nowPlayingMediaForController:controller];
    SRGChannel *channel = controller.channel;
    
    if (media.contentType == SRGContentTypeLivestream && channel) {
        // Display program information (if any) when the controller position is within the current program, otherwise channel
        // information.
        NSDate *playbackDate = controller.date;
        if (playbackDate && [channel.currentProgram srgletterbox_containsDate:playbackDate]) {
            artworkURL = SRGLetterboxArtworkImageURL(channel.currentProgram, smallestDimension);
            if (! artworkURL) {
                artworkURL = SRGLetterboxArtworkImageURL(channel, smallestDimension);
            }
        }
        else {
            artworkURL = SRGLetterboxArtworkImageURL(channel, smallestDimension);
        }
    }
    else {
        artworkURL = SRGLetterboxArtworkImageURL(media, smallestDimension);
    }
    
    if (! artworkURL) {
        artworkURL = [UIImage srg_URLForVectorImageAtPath:SRGLetterboxMediaArtworkPlaceholderFilePath() withSize:size];
    }
    
    NSAssert(artworkURL != nil, @"An artwork URL must always be returned");
    return artworkURL;
}

// Return the best available image to display in the control center, performing an update only when an image is not
// readily available from the cache
- (UIImage *)cachedArtworkImageForController:(SRGLetterboxController *)controller withSize:(CGSize)size
{
    NSURL *artworkURL = [self artworkURLForController:controller withSize:size];
    if (! [artworkURL isEqual:self.cachedArtworkURL] || ! self.cachedArtworkImage) {
        // SRGLetterboxImageURL might return file URLs for overridden images
        if (artworkURL.fileURL) {
            UIImage *image = [UIImage imageWithContentsOfFile:artworkURL.path];
            self.cachedArtworkURL = artworkURL;
            self.cachedArtworkImage = image;
            return image;
        }
        else {
            NSURL *placeholderImageURL = [UIImage srg_URLForVectorImageAtPath:SRGLetterboxMediaArtworkPlaceholderFilePath() withSize:size];
            UIImage *placeholderImage = [UIImage imageWithContentsOfFile:placeholderImageURL.path];
            
            // Request the image when not available. Calling -cachedArtworkImageForController:withSize: will then return
            // it when it has been downloaded.
            self.imageOperation = [[YYWebImageManager sharedManager] requestImageWithURL:artworkURL options:0 progress:nil transform:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
                if (image) {
                    self.cachedArtworkURL = artworkURL;
                    self.cachedArtworkImage = image;
                }
                else {
                    self.cachedArtworkURL = placeholderImageURL;
                    self.cachedArtworkImage = placeholderImage;
                }
            }];
            
            // Keep the current artwork during retrieval (even if it does not match) for smoother transitions, or use
            // the placeholder when none
            return self.cachedArtworkImage ?: placeholderImage;
        }
    }
    else {
        return self.cachedArtworkImage;
    }
}

- (void)clearArtworkImageCache
{
    self.cachedArtworkURL = nil;
    self.cachedArtworkImage = nil;
}

- (MPRemoteCommandHandlerStatus)play:(MPRemoteCommandEvent *)event
{
    [self.controller.mediaPlayerController play];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)pause:(MPRemoteCommandEvent *)event
{
    [self.controller.mediaPlayerController pause];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)togglePlayPause:(MPRemoteCommandEvent *)event
{
    [self.controller.mediaPlayerController togglePlayPause];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)skipForward:(MPRemoteCommandEvent *)event
{
    return [self.controller skipForwardWithCompletionHandler:nil] ? MPRemoteCommandHandlerStatusSuccess : MPRemoteCommandHandlerStatusCommandFailed;
}

- (MPRemoteCommandHandlerStatus)skipBackward:(MPRemoteCommandEvent *)event
{
    return [self.controller skipBackwardWithCompletionHandler:nil] ? MPRemoteCommandHandlerStatusSuccess : MPRemoteCommandHandlerStatusCommandFailed;
}

- (MPRemoteCommandHandlerStatus)seekForward:(MPSeekCommandEvent *)event
{
    if (event.type == MPSeekCommandEventTypeBeginSeeking) {
        return [self.controller skipForwardWithCompletionHandler:nil] ? MPRemoteCommandHandlerStatusSuccess : MPRemoteCommandHandlerStatusCommandFailed;
    }
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)seekBackward:(MPSeekCommandEvent *)event
{
    if (event.type == MPSeekCommandEventTypeBeginSeeking) {
        return [self.controller skipBackwardWithCompletionHandler:nil] ? MPRemoteCommandHandlerStatusSuccess : MPRemoteCommandHandlerStatusCommandFailed;
    }
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)previousTrack:(MPRemoteCommandEvent *)event
{
    return [self.controller playPreviousMedia] ? MPRemoteCommandHandlerStatusSuccess : MPRemoteCommandHandlerStatusNoSuchContent;
}

- (MPRemoteCommandHandlerStatus)nextTrack:(MPRemoteCommandEvent *)event
{
    return [self.controller playNextMedia] ? MPRemoteCommandHandlerStatusSuccess : MPRemoteCommandHandlerStatusNoSuchContent;
}

- (MPRemoteCommandHandlerStatus)doNothing:(MPRemoteCommandEvent *)event
{
    return MPRemoteCommandHandlerStatusSuccess;
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
    return [NSString stringWithFormat:@"<%@: %p; controller = %@; pictureInPictureDelegate = %@>",
            self.class,
            self,
            self.controller,
            self.pictureInPictureDelegate];
}

@end
