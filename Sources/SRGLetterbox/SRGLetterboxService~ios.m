//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGLetterboxService.h"

#import "MPRemoteCommand+SRGLetterbox.h"
#import "SRGLetterboxController+Private.h"
#import "SRGLetterboxLogger.h"
#import "SRGLetterboxMetadata.h"
#import "UIDevice+SRGLetterbox.h"
#import "UIImage+SRGLetterbox.h"

@import FXReachability;
@import libextobjc;
@import MAKVONotificationCenter;
@import MediaPlayer;
@import SRGAppearance;
@import SRGMediaPlayer;
@import YYWebImage;

NSString * const SRGLetterboxServiceSettingsDidChangeNotification = @"SRGLetterboxServiceSettingsDidChangeNotification";

static MPNowPlayingInfoLanguageOptionGroup *SRGLetterboxServiceLanguageOptionGroup(NSArray<AVMediaSelectionOption *> *selectionOption, BOOL allowEmptySelection);

@interface SRGLetterboxService () <AVPictureInPictureControllerDelegate> {
@private
    BOOL _restoreUserInterface;
    BOOL _playbackStopped;
}

@property (nonatomic) SRGLetterboxController *controller;
@property (nonatomic, weak) id<SRGLetterboxPictureInPictureDelegate> pictureInPictureDelegate;
@property (nonatomic) id<SRGLetterboxPictureInPictureDelegate> activePictureInPictureDelegate;      // Strong ref during PiP use

@property (nonatomic, getter=areNowPlayingInfoAndCommandsEnabled) BOOL nowPlayingInfoAndCommandsEnabled;
@property (nonatomic, getter=areNowPlayingInfoAndCommandsInstalled) BOOL nowPlayingInfoAndCommandsInstalled;
@property (nonatomic) SRGLetterboxCommands allowedCommands;

@property (nonatomic, weak) id periodicTimeObserver;
@property (nonatomic) YYWebImageOperation *imageOperation;

@property (atomic) NSURL *cachedArtworkURL;
@property (atomic) UIImage *cachedArtworkImage;
@property (atomic) NSError *cachedArtworkError;

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
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(audioSessionInterruption:)
                                                   name:AVAudioSessionInterruptionNotification
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(rechabilityDidChange:)
                                                   name:FXReachabilityStatusDidChangeNotification
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
}

#pragma mark Getters and setters

- (void)setNowPlayingInfoAndCommandsEnabled:(BOOL)nowPlayingInfoAndCommandsEnabled
{
    _nowPlayingInfoAndCommandsEnabled = nowPlayingInfoAndCommandsEnabled;
    [self updateMetadataWithController:self.controller];
}

- (void)setAllowedCommands:(SRGLetterboxCommands)allowedCommands
{
    _allowedCommands = allowedCommands;
    [self updateRemoteCommandCenterWithController:self.controller];
}

- (void)setController:(SRGLetterboxController *)controller
{
    if (_controller == controller) {
        return;
    }
    
    if (_controller) {
        [self disableExternalPlaybackForController:_controller];
        
        [_controller removeObserver:self keyPath:@keypath(_controller.media)];
        
        SRGMediaPlayerController *previousMediaPlayerController = _controller.mediaPlayerController;
        [previousMediaPlayerController removeObserver:self keyPath:@keypath(previousMediaPlayerController.playbackRate)];
        [previousMediaPlayerController removeObserver:self keyPath:@keypath(previousMediaPlayerController.effectivePlaybackRate)];
        
        AVPictureInPictureController *pictureInPictureController = previousMediaPlayerController.pictureInPictureController;
        [pictureInPictureController removeObserver:self keyPath:@keypath(pictureInPictureController.pictureInPictureActive)];
        
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGLetterboxMetadataDidChangeNotification
                                                    object:_controller];
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                    object:previousMediaPlayerController];
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGMediaPlayerSeekNotification
                                                    object:previousMediaPlayerController];
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGMediaPlayerAudioTrackDidChangeNotification
                                                    object:previousMediaPlayerController];
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGMediaPlayerSubtitleTrackDidChangeNotification
                                                    object:previousMediaPlayerController];
        
        [previousMediaPlayerController removePeriodicTimeObserver:self.periodicTimeObserver];
    }
    
    _controller = controller;
    
    [self updateMetadataWithController:controller];
    
    if (controller) {
        // Do not switch to external playback when playing anything other than videos. External playback is namely only
        // intended for video playback. If you try to play audio with external playback, then:
        //   - The screen will be black instead of displaying a media notification.
        //   - The user won't be able to change the volume with the phone controls.
        // Remark: For video external playback, it is normal that the user cannot control the volume from her device.
        @weakify(controller)
        [controller addObserver:self keyPath:@keypath(controller.media) options:0 block:^(MAKVONotification *notification) {
            @strongify(controller)
            [self enableExternalPlaybackForController:controller];
        }];
        [self enableExternalPlaybackForController:controller];
        
        SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
        [mediaPlayerController addObserver:self keyPath:@keypath(mediaPlayerController.playbackRate) options:0 block:^(MAKVONotification *notification) {
            @strongify(controller)
            [self updateNowPlayingInformationWithController:controller];
        }];
        [mediaPlayerController addObserver:self keyPath:@keypath(mediaPlayerController.effectivePlaybackRate) options:0 block:^(MAKVONotification *notification) {
            @strongify(controller)
            [self updateNowPlayingInformationWithController:controller];
        }];
        
        AVPictureInPictureController *pictureInPictureController = mediaPlayerController.pictureInPictureController;
        if (pictureInPictureController) {
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
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(playbackStateDidChange:)
                                                   name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                 object:mediaPlayerController];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(playerSeek:)
                                                   name:SRGMediaPlayerSeekNotification
                                                 object:mediaPlayerController];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(audioTrackDidChange:)
                                                   name:SRGMediaPlayerAudioTrackDidChangeNotification
                                                 object:mediaPlayerController];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(subtitleTrackDidChange:)
                                                   name:SRGMediaPlayerSubtitleTrackDidChangeNotification
                                                 object:mediaPlayerController];
        
        @weakify(self)
        self.periodicTimeObserver = [mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
            @strongify(self)
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
    
    self.pictureInPictureDelegate = [AVPictureInPictureController isPictureInPictureSupported] ? pictureInPictureDelegate : nil;
    self.activePictureInPictureDelegate = nil;
    
    self.controller.mediaPlayerController.pictureInPictureEnabled = NO;
    self.controller = controller;
    self.controller.mediaPlayerController.pictureInPictureEnabled = (self.pictureInPictureDelegate != nil);
    
    [self updateMetadataWithController:controller];
    
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
    self.activePictureInPictureDelegate = nil;
    
    [self updateRemoteCommandCenterWithController:nil];
    
    [NSNotificationCenter.defaultCenter postNotificationName:SRGLetterboxServiceSettingsDidChangeNotification object:self];
}

#pragma mark External playback

- (void)enableExternalPlaybackForController:(SRGLetterboxController *)controller
{
    [controller setAllowsExternalPlayback:(controller.media.mediaType == SRGMediaTypeVideo)
          usedWhileExternalScreenIsActive:! self.mirroredOnExternalScreen];
}

- (void)disableExternalPlaybackForController:(SRGLetterboxController *)controller
{
    [controller setAllowsExternalPlayback:NO usedWhileExternalScreenIsActive:NO];
}

#pragma mark Control center and lock screen integration

- (void)setupRemoteCommandCenter
{
    NSAssert(! self.nowPlayingInfoAndCommandsInstalled, @"Must not be installed");
    
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    MPRemoteCommand *playCommand = commandCenter.playCommand;
    playCommand.enabled = NO;
    [playCommand srg_addUniqueTarget:self action:@selector(play:)];
    
    MPRemoteCommand *pauseCommand = commandCenter.pauseCommand;
    pauseCommand.enabled = NO;
    [pauseCommand srg_addUniqueTarget:self action:@selector(pause:)];
    
    MPRemoteCommand *stopCommand = commandCenter.stopCommand;
    stopCommand.enabled = NO;
    [stopCommand srg_addUniqueTarget:self action:@selector(stop:)];
    
    MPRemoteCommand *togglePlayPauseCommand = commandCenter.togglePlayPauseCommand;
    togglePlayPauseCommand.enabled = NO;
    [togglePlayPauseCommand srg_addUniqueTarget:self action:@selector(togglePlayPause:)];
    
    MPSkipIntervalCommand *skipForwardIntervalCommand = commandCenter.skipForwardCommand;
    skipForwardIntervalCommand.enabled = NO;
    skipForwardIntervalCommand.preferredIntervals = @[@(SRGLetterboxSkipInterval)];
    [skipForwardIntervalCommand srg_addUniqueTarget:self action:@selector(skipForward:)];
    
    MPSkipIntervalCommand *skipBackwardIntervalCommand = commandCenter.skipBackwardCommand;
    skipBackwardIntervalCommand.enabled = NO;
    skipBackwardIntervalCommand.preferredIntervals = @[@(SRGLetterboxSkipInterval)];
    [skipBackwardIntervalCommand srg_addUniqueTarget:self action:@selector(skipBackward:)];
    
    MPRemoteCommand *previousTrackCommand = commandCenter.previousTrackCommand;
    previousTrackCommand.enabled = NO;
    [previousTrackCommand srg_addUniqueTarget:self action:@selector(previousTrack:)];
    
    MPRemoteCommand *nextTrackCommand = commandCenter.nextTrackCommand;
    nextTrackCommand.enabled = NO;
    [nextTrackCommand srg_addUniqueTarget:self action:@selector(nextTrack:)];
    
    MPRemoteCommand *changePlaybackPositionCommand = commandCenter.changePlaybackPositionCommand;
    changePlaybackPositionCommand.enabled = NO;
    [changePlaybackPositionCommand srg_addUniqueTarget:self action:@selector(changePlaybackPosition:)];

    MPRemoteCommand *enableLanguageOptionCommand = commandCenter.enableLanguageOptionCommand;
    enableLanguageOptionCommand.enabled = NO;
    [enableLanguageOptionCommand srg_addUniqueTarget:self action:@selector(enableLanguageOption:)];
    
    MPRemoteCommand *disableLanguageOptionCommand = commandCenter.disableLanguageOptionCommand;
    disableLanguageOptionCommand.enabled = NO;
    [disableLanguageOptionCommand srg_addUniqueTarget:self action:@selector(disableLanguageOption:)];
    
    MPChangePlaybackRateCommand *changePlaybackRateCommand = commandCenter.changePlaybackRateCommand;
    changePlaybackRateCommand.supportedPlaybackRates = self.controller.supportedPlaybackRates;
    changePlaybackRateCommand.enabled = NO;
    [changePlaybackRateCommand srg_addUniqueTarget:self action:@selector(changePlaybackRate:)];
}

- (void)resetRemoteCommandCenter
{
    NSAssert(self.nowPlayingInfoAndCommandsInstalled, @"Must be installed");
    
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    MPRemoteCommand *playCommand = commandCenter.playCommand;
    [playCommand removeTarget:self action:@selector(play:)];
    
    MPRemoteCommand *pauseCommand = commandCenter.pauseCommand;
    [pauseCommand removeTarget:self action:@selector(pause:)];
    
    MPRemoteCommand *stopCommand = commandCenter.stopCommand;
    [stopCommand removeTarget:self action:@selector(stop:)];
    
    MPRemoteCommand *togglePlayPauseCommand = commandCenter.togglePlayPauseCommand;
    [togglePlayPauseCommand removeTarget:self action:@selector(togglePlayPause:)];
    
    MPSkipIntervalCommand *skipForwardIntervalCommand = commandCenter.skipForwardCommand;
    [skipForwardIntervalCommand removeTarget:self action:@selector(skipForward:)];
    
    MPSkipIntervalCommand *skipBackwardIntervalCommand = commandCenter.skipBackwardCommand;
    [skipBackwardIntervalCommand removeTarget:self action:@selector(skipBackward:)];
    
    MPRemoteCommand *previousTrackCommand = commandCenter.previousTrackCommand;
    [previousTrackCommand removeTarget:self action:@selector(previousTrack:)];
    
    MPRemoteCommand *nextTrackCommand = commandCenter.nextTrackCommand;
    [nextTrackCommand removeTarget:self action:@selector(nextTrack:)];

    MPRemoteCommand *changePlaybackPositionCommand = commandCenter.changePlaybackPositionCommand;
    [changePlaybackPositionCommand removeTarget:self action:@selector(changePlaybackPosition:)];
    
    MPRemoteCommand *enableLanguageOptionCommand = commandCenter.enableLanguageOptionCommand;
    [enableLanguageOptionCommand removeTarget:self action:@selector(enableLanguageOption:)];
    
    MPRemoteCommand *disableLanguageOptionCommand = commandCenter.disableLanguageOptionCommand;
    [disableLanguageOptionCommand removeTarget:self action:@selector(disableLanguageOption:)];
    
    MPChangePlaybackRateCommand *changePlaybackRateCommand = commandCenter.changePlaybackRateCommand;
    [changePlaybackRateCommand removeTarget:self action:@selector(changePlaybackRate:)];
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
                                                                                                            || UIApplication.sharedApplication.applicationState != UIApplicationStateBackground
                                                                                                            || AVAudioSession.srg_isAirPlayActive
                                                                                                            || controller.pictureInPictureActive
                                                                                                            || UIDevice.srg_letterbox_isLocked)) {
        commandCenter.playCommand.enabled = YES;
        commandCenter.pauseCommand.enabled = YES;
        commandCenter.stopCommand.enabled = YES;
        commandCenter.togglePlayPauseCommand.enabled = YES;
        commandCenter.skipForwardCommand.enabled = (self.allowedCommands & SRGLetterboxCommandSkipForward) && [controller canSkipForward];
        commandCenter.skipBackwardCommand.enabled = (self.allowedCommands & SRGLetterboxCommandSkipBackward) && [controller canSkipBackward];
        commandCenter.nextTrackCommand.enabled = (self.allowedCommands & SRGLetterboxCommandNextTrack) && [controller canPlayNextMedia];
        commandCenter.previousTrackCommand.enabled = (self.allowedCommands & SRGLetterboxCommandPreviousTrack) && [controller canPlayPreviousMedia];
        commandCenter.changePlaybackPositionCommand.enabled = (self.allowedCommands & SRGLetterboxCommandChangePlaybackPosition) && SRG_CMTIMERANGE_IS_NOT_EMPTY(controller.timeRange);
        commandCenter.enableLanguageOptionCommand.enabled = (self.allowedCommands & SRGLetterboxCommandLanguageSelection);
        commandCenter.disableLanguageOptionCommand.enabled = (self.allowedCommands & SRGLetterboxCommandLanguageSelection);
        commandCenter.changePlaybackRateCommand.enabled = (self.allowedCommands & SRGLetterboxCommandChangePlaybackRate) && (mediaPlayerController.streamType != SRGStreamTypeLive);
    }
    else {
        commandCenter.playCommand.enabled = NO;
        commandCenter.pauseCommand.enabled = NO;
        commandCenter.stopCommand.enabled = NO;
        commandCenter.togglePlayPauseCommand.enabled = NO;
        commandCenter.skipForwardCommand.enabled = NO;
        commandCenter.skipBackwardCommand.enabled = NO;
        commandCenter.nextTrackCommand.enabled = NO;
        commandCenter.previousTrackCommand.enabled = NO;
        commandCenter.changePlaybackPositionCommand.enabled = NO;
        commandCenter.enableLanguageOptionCommand.enabled = NO;
        commandCenter.disableLanguageOptionCommand.enabled = NO;
        commandCenter.changePlaybackRateCommand.enabled = NO;
    }
}

- (void)updateNowPlayingInformationWithController:(SRGLetterboxController *)controller
{
    if (! self.nowPlayingInfoAndCommandsEnabled) {
        return;
    }
    
    SRGLetterboxLogDebug(@"service", @"Now playing info metadata update started");
    
    SRGMedia *media = controller.displayableMedia;
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
    
    nowPlayingInfo[MPMediaItemPropertyTitle] = SRGLetterboxMetadataTitle(media);
    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = SRGLetterboxMetadataSubtitle(media);
    nowPlayingInfo[MPMediaItemPropertyArtist] = @"";
    
    static const SRGImageWidth kWidth = SRGImageWidth480;
    
    // A subtle issue might arise if the controller is strongly captured by the block (successive now playing information
    // center updates might deadlock).
    @weakify(self) @weakify(controller)
    UIImage *artworkImage = [self cachedArtworkImageForController:controller withWidth:kWidth completion:^{
        @strongify(self) @strongify(controller)
        [self updateNowPlayingInformationWithController:controller];
    }];
    if (artworkImage) {
        nowPlayingInfo[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithBoundsSize:CGSizeMake(kWidth, kWidth) requestHandler:^UIImage * _Nonnull(CGSize size) {
            // Return the closest image we have, see https://developer.apple.com/videos/play/wwdc2017/251. Here just
            // the image we retrieved for this specific purpose.
            return artworkImage;
        }];
    }
    else {
        nowPlayingInfo[MPMediaItemPropertyArtwork] = nil;
    }
    
    SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
    
    CMTimeRange timeRange = mediaPlayerController.timeRange;
    CMTime time = CMTIME_IS_INDEFINITE(mediaPlayerController.seekTargetTime) ? mediaPlayerController.currentTime : mediaPlayerController.seekTargetTime;
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(CMTimeGetSeconds(CMTimeSubtract(time, timeRange.start)));
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @(CMTimeGetSeconds(timeRange.duration));
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = @(mediaPlayerController.effectivePlaybackRate);
    nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = @(mediaPlayerController.playbackRate);
    
    BOOL isLivestream = (mediaPlayerController.streamType == SRGMediaPlayerStreamTypeLive);
    nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = @(isLivestream);
    
    // Audio tracks and subtitles
    NSMutableArray<MPNowPlayingInfoLanguageOptionGroup *> *languageOptionGroups = [NSMutableArray array];
    NSMutableArray<MPNowPlayingInfoLanguageOption *> *currentLanguageOptions = [NSMutableArray array];
    
    AVPlayerItem *playerItem = mediaPlayerController.player.currentItem;
    AVAsset *asset = playerItem.asset;
    if ([asset statusOfValueForKey:@keypath(asset.availableMediaCharacteristicsWithMediaSelectionOptions) error:NULL] == AVKeyValueStatusLoaded) {
        AVMediaSelectionGroup *audioGroup = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
        NSArray<AVMediaSelectionOption *> *audioOptions = audioGroup.options;
        if (audioOptions.count > 1) {
            [languageOptionGroups addObject:SRGLetterboxServiceLanguageOptionGroup(audioOptions, NO)];
            
            AVMediaSelectionOption *selectedAudibleOption = [playerItem.currentMediaSelection selectedMediaOptionInMediaSelectionGroup:audioGroup];
            if (selectedAudibleOption) {
                [currentLanguageOptions addObject:[selectedAudibleOption makeNowPlayingInfoLanguageOption]];
            }
        }
        
        AVMediaSelectionGroup *subtitleGroup = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
        NSArray<AVMediaSelectionOption *> *subtitleOptions = [AVMediaSelectionGroup mediaSelectionOptionsFromArray:subtitleGroup.options withoutMediaCharacteristics:@[AVMediaCharacteristicContainsOnlyForcedSubtitles]];
        if (subtitleOptions.count > 0) {
            [languageOptionGroups addObject:SRGLetterboxServiceLanguageOptionGroup(subtitleOptions, YES)];
        }
        
        AVMediaSelectionOption *selectedLegibleOption = [playerItem.currentMediaSelection selectedMediaOptionInMediaSelectionGroup:subtitleGroup];
        if (selectedLegibleOption) {
            [currentLanguageOptions addObject:[selectedLegibleOption makeNowPlayingInfoLanguageOption]];
        }
    }
    
    nowPlayingInfo[MPNowPlayingInfoPropertyAvailableLanguageOptions] = languageOptionGroups.copy;
    nowPlayingInfo[MPNowPlayingInfoPropertyCurrentLanguageOptions] = currentLanguageOptions.copy;
    
    MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = nowPlayingInfo.copy;
}

- (void)updateMetadataWithController:(SRGLetterboxController *)controller
{
    if (self.nowPlayingInfoAndCommandsEnabled && controller && controller.playbackState != SRGMediaPlayerPlaybackStateIdle) {
        if (! self.nowPlayingInfoAndCommandsInstalled) {
            [self setupRemoteCommandCenter];
            self.nowPlayingInfoAndCommandsInstalled = YES;
        }
        [self updateNowPlayingInformationWithController:controller];
        [self updateRemoteCommandCenterWithController:controller];
    }
    else if (self.nowPlayingInfoAndCommandsInstalled) {
        [self resetRemoteCommandCenter];
        MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = nil;
        self.nowPlayingInfoAndCommandsInstalled = NO;
    }
}

- (NSURL *)artworkURLForController:(SRGLetterboxController *)controller withWidth:(SRGImageWidth)width
{
    SRGMedia *media = controller.displayableMedia;
    NSURL *artworkURL = SRGLetterboxImageURL(media.image, width, controller);
    if (! artworkURL) {
        artworkURL = [UIImage srg_URLForVectorImageAtPath:SRGLetterboxFilePathForImagePlaceholder() withWidth:width];
    }
    
    NSAssert(artworkURL != nil, @"An artwork URL must always be returned");
    return artworkURL;
}

// Return the best available image to display in the control center, performing an asynchronous update only when an image is not
// readily available from the cache
- (UIImage *)cachedArtworkImageForController:(SRGLetterboxController *)controller withWidth:(SRGImageWidth)width completion:(void (^)(void))completion
{
    NSURL *artworkURL = [self artworkURLForController:controller withWidth:width];
    if (! [artworkURL isEqual:self.cachedArtworkURL] || ! self.cachedArtworkImage) {
        // SRGLetterboxImageURL might return file URLs for overridden images
        if (artworkURL.fileURL) {
            UIImage *image = [UIImage imageWithContentsOfFile:artworkURL.path];
            self.cachedArtworkURL = artworkURL;
            self.cachedArtworkImage = image;
            self.cachedArtworkError = nil;
            return image;
        }
        else {
            NSURL *placeholderImageURL = [UIImage srg_URLForVectorImageAtPath:SRGLetterboxFilePathForImagePlaceholder() withWidth:width];
            UIImage *placeholderImage = [UIImage imageWithContentsOfFile:placeholderImageURL.path];
            
            SRGLetterboxLogDebug(@"service", @"Artwork image update triggered");
            
            // Request the image when not available. Calling -cachedArtworkImageForController:withSize: once the completion handler is called
            // will then return the image immediately
            @weakify(self)
            self.imageOperation = [[YYWebImageManager sharedManager] requestImageWithURL:artworkURL options:0 progress:nil transform:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
                @strongify(self)
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.cachedArtworkURL = artworkURL;
                    self.cachedArtworkImage = image ?: placeholderImage;
                    self.cachedArtworkError = error;
                    
                    completion ? completion() : nil;
                });
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
    self.cachedArtworkError = nil;
}

#pragma mark Remote commands

- (MPRemoteCommandHandlerStatus)play:(MPRemoteCommandEvent *)event
{
    [self.controller play];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)pause:(MPRemoteCommandEvent *)event
{
    [self.controller pause];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)stop:(MPRemoteCommandEvent *)event
{
    [self.controller stop];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)togglePlayPause:(MPRemoteCommandEvent *)event
{
    [self.controller togglePlayPause];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)skipForward:(MPSkipIntervalCommandEvent *)event
{
    return [self.controller skipWithInterval:event.interval completionHandler:nil] ? MPRemoteCommandHandlerStatusSuccess : MPRemoteCommandHandlerStatusCommandFailed;
}

- (MPRemoteCommandHandlerStatus)skipBackward:(MPSkipIntervalCommandEvent *)event
{
    return [self.controller skipWithInterval:-event.interval completionHandler:nil] ? MPRemoteCommandHandlerStatusSuccess : MPRemoteCommandHandlerStatusCommandFailed;
}

- (MPRemoteCommandHandlerStatus)previousTrack:(MPRemoteCommandEvent *)event
{
    if ([self.controller playPreviousMedia]) {
        return MPRemoteCommandHandlerStatusSuccess;
    }
    else {
        return MPRemoteCommandHandlerStatusNoActionableNowPlayingItem;
    }
}

- (MPRemoteCommandHandlerStatus)nextTrack:(MPRemoteCommandEvent *)event
{
    if ([self.controller playNextMedia]) {
        return MPRemoteCommandHandlerStatusSuccess;
    }
    else {
        return MPRemoteCommandHandlerStatusNoActionableNowPlayingItem;
    }
}

- (MPRemoteCommandHandlerStatus)changePlaybackPosition:(MPChangePlaybackPositionCommandEvent *)event
{
    CMTime time = CMTimeAdd(self.controller.timeRange.start, CMTimeMakeWithSeconds(event.positionTime, NSEC_PER_SEC));
    SRGPosition *position = [SRGPosition positionAroundTime:time];
    [self.controller seekToPosition:position withCompletionHandler:^(BOOL finished) {
        // Resume playback when seeking from the control center. It namely does not make sense to seek blindly
        // without playback actually resuming if paused.
        if (finished) {
            [self.controller play];
        }
    }];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)enableLanguageOption:(MPChangeLanguageOptionCommandEvent *)event
{
    AVPlayerItem *playerItem = self.controller.mediaPlayerController.player.currentItem;
    AVAsset *asset = playerItem.asset;
    if ([asset statusOfValueForKey:@keypath(asset.availableMediaCharacteristicsWithMediaSelectionOptions) error:NULL] != AVKeyValueStatusLoaded) {
        return MPRemoteCommandHandlerStatusNoActionableNowPlayingItem;
    }
    
    BOOL (^selectLanguageOptionInGroup)(MPNowPlayingInfoLanguageOption *, AVMediaSelectionGroup *) = ^(MPNowPlayingInfoLanguageOption *languageOption, AVMediaSelectionGroup *group) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(AVMediaSelectionOption * _Nullable option, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [option.extendedLanguageTag isEqualToString:languageOption.languageTag];
        }];
        AVMediaSelectionOption *option = [[AVMediaSelectionGroup mediaSelectionOptionsFromArray:group.options withMediaCharacteristics:languageOption.languageOptionCharacteristics] filteredArrayUsingPredicate:predicate].firstObject;
        if (! option) {
            return NO;
        }
        
        [playerItem selectMediaOption:option inMediaSelectionGroup:group];
        return YES;
    };
    
    MPNowPlayingInfoLanguageOption *languageOption = event.languageOption;
    if (languageOption.languageOptionType == MPNowPlayingInfoLanguageOptionTypeLegible) {
        AVMediaSelectionGroup *group = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
        if ([languageOption isAutomaticLegibleLanguageOption]) {
            [playerItem selectMediaOptionAutomaticallyInMediaSelectionGroup:group];
        }
        else if (! selectLanguageOptionInGroup(languageOption, group)) {
            return MPRemoteCommandHandlerStatusCommandFailed;
        }
    }
    else {
        AVMediaSelectionGroup *group = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
        if ([languageOption isAutomaticAudibleLanguageOption]) {
            [playerItem selectMediaOptionAutomaticallyInMediaSelectionGroup:group];
        }
        else if (! selectLanguageOptionInGroup(languageOption, group)) {
            return MPRemoteCommandHandlerStatusCommandFailed;
        }
    }
    
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)disableLanguageOption:(MPChangeLanguageOptionCommandEvent *)event
{
    AVPlayerItem *playerItem = self.controller.mediaPlayerController.player.currentItem;
    AVAsset *asset = playerItem.asset;
    if ([asset statusOfValueForKey:@keypath(asset.availableMediaCharacteristicsWithMediaSelectionOptions) error:NULL] != AVKeyValueStatusLoaded) {
        return MPRemoteCommandHandlerStatusNoActionableNowPlayingItem;
    }
    
    MPNowPlayingInfoLanguageOption *languageOption = event.languageOption;
    if (languageOption.languageOptionType == MPNowPlayingInfoLanguageOptionTypeLegible) {
        AVMediaSelectionGroup *subtitleGroup = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
        [playerItem selectMediaOption:nil inMediaSelectionGroup:subtitleGroup];
    }
    else {
        AVMediaSelectionGroup *audioGroup = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
        [playerItem selectMediaOption:nil inMediaSelectionGroup:audioGroup];
    }
    
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)changePlaybackRate:(MPChangePlaybackRateCommandEvent *)event
{
    self.controller.playbackRate = event.playbackRate;
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
    self.activePictureInPictureDelegate = self.pictureInPictureDelegate;
    
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
    
    self.activePictureInPictureDelegate = nil;
}

#pragma mark Notifications

- (void)metadataDidChange:(NSNotification *)notification
{
    [self updateNowPlayingInformationWithController:self.controller];
}

- (void)playbackStateDidChange:(NSNotification *)notification
{
    [self updateMetadataWithController:self.controller];
}

- (void)playerSeek:(NSNotification *)notification
{
    [self updateMetadataWithController:self.controller];
}

- (void)audioTrackDidChange:(NSNotification *)notification
{
    [self updateNowPlayingInformationWithController:self.controller];
}

- (void)subtitleTrackDidChange:(NSNotification *)notification
{
    [self updateNowPlayingInformationWithController:self.controller];
}

// Update commands while transitioning from / to the background (since control availability might be affected)
- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    // To determine whether a background entry is due to the lock screen being enabled or not, we need to wait a little bit.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateRemoteCommandCenterWithController:self.controller];
    });
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self updateRemoteCommandCenterWithController:self.controller];
}

- (void)audioSessionInterruption:(NSNotification *)notification
{
    AVAudioSessionInterruptionType interruptionType = [notification.userInfo[AVAudioSessionInterruptionTypeKey] integerValue];
    if (interruptionType == AVAudioSessionInterruptionTypeEnded) {
        AVAudioSessionInterruptionOptions interruptionOption = [notification.userInfo[AVAudioSessionInterruptionOptionKey] integerValue];
        if (interruptionOption == AVAudioSessionInterruptionOptionShouldResume) {
            [self.controller play];
        }
    }
}

- (void)rechabilityDidChange:(NSNotification *)notification
{
    if ([FXReachability sharedInstance].reachable) {
        if (self.cachedArtworkError) {
            self.cachedArtworkImage = nil;
            self.cachedArtworkURL = nil;
            self.cachedArtworkError = nil;
            
            [self updateNowPlayingInformationWithController:self.controller];
        }
    }
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

#pragma mark Functions

// Cannot use `-makeNowPlayingInfoLanguageOptionGroup` for groups for which Off is not an option.
static MPNowPlayingInfoLanguageOptionGroup *SRGLetterboxServiceLanguageOptionGroup(NSArray<AVMediaSelectionOption *> *selectionOptions, BOOL allowEmptySelection)
{
    NSMutableArray<MPNowPlayingInfoLanguageOption *> *languageOptions = [NSMutableArray array];
    
    [selectionOptions enumerateObjectsUsingBlock:^(AVMediaSelectionOption * _Nonnull selectionOption, NSUInteger idx, BOOL * _Nonnull stop) {
        [languageOptions addObject:[selectionOption makeNowPlayingInfoLanguageOption]];
    }];
    
    return [[MPNowPlayingInfoLanguageOptionGroup alloc] initWithLanguageOptions:languageOptions.copy
                                                          defaultLanguageOption:nil
                                                            allowEmptySelection:allowEmptySelection];
}

#endif
