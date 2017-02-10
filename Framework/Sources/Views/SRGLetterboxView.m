//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxView.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxController+Private.h"
#import "SRGLetterboxError.h"
#import "SRGLetterboxLogger.h"
#import "SRGLetterboxService+Private.h"
#import "UIFont+SRGLetterbox.h"
#import "UIImageView+SRGLetterbox.h"

#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <Masonry/Masonry.h>
#import <libextobjc/libextobjc.h>
#import <ASValueTrackingSlider/ASValueTrackingSlider.h>

static void commonInit(SRGLetterboxView *self);

@interface SRGLetterboxView () <ASValueTrackingSliderDataSource>

// UI
@property (nonatomic, weak) IBOutlet UIView *playerView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIView *controlsView;
@property (nonatomic, weak) IBOutlet SRGPlaybackButton *playbackButton;
@property (nonatomic, weak) IBOutlet ASValueTrackingSlider *timeSlider;
@property (nonatomic, weak) IBOutlet UIButton *forwardSeekButton;
@property (nonatomic, weak) IBOutlet UIButton *backwardSeekButton;

@property (nonatomic, weak) UIImageView *loadingImageView;

@property (nonatomic, weak) IBOutlet UIView *errorView;
@property (nonatomic, weak) IBOutlet UILabel *errorLabel;

@property (nonatomic, weak) IBOutlet SRGPictureInPictureButton *pictureInPictureButton;

@property (nonatomic, weak) IBOutlet SRGAirplayView *airplayView;
@property (nonatomic, weak) IBOutlet UILabel *airplayLabel;
@property (nonatomic, weak) IBOutlet SRGAirplayButton *airplayButton;
@property (nonatomic, weak) IBOutlet SRGTracksButton *tracksButton;
@property (nonatomic, weak) IBOutlet UIButton *fullScreenButton;

// Internal
@property (nonatomic) NSTimer *inactivityTimer;
@property (nonatomic, weak) id periodicTimeObserver;

@property (nonatomic, getter=isUserInterfaceHidden) BOOL userInterfaceHidden;
@property (nonatomic, getter=isUserInterfaceTogglable) BOOL userInterfaceTogglable;
@property (nonatomic, getter=isFullScreen) BOOL fullScreen;
@property (nonatomic, getter=isFullScreenAnimationRunning) BOOL fullScreenAnimationRunning;
@property (nonatomic, getter=isShowingPopup) BOOL showingPopup;

// Backup value for Airplay playback
@property (nonatomic) BOOL wasUserInterfaceTogglable;

@property (nonatomic, copy) void (^animations)(BOOL hidden);
@property (nonatomic, copy) void (^completion)(BOOL finished);

@end

@implementation SRGLetterboxView {
@private
    BOOL _inWillAnimateUserInterface;
}

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        commonInit(self);
    }
    return self;
}

- (void)dealloc
{
    self.controller = nil;
}

#pragma mark View lifecycle

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // FIXME: Currently added in code, but we should provide a more customizable activity indicator
    //        in the SRG Media Player library soon. Replace when available
    UIImageView *loadingImageView = [UIImageView srg_loadingImageView35WithTintColor:[UIColor whiteColor]];
    loadingImageView.alpha = 0.f;
    [self.playerView insertSubview:loadingImageView aboveSubview:self.playbackButton];
    [loadingImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.playbackButton.mas_top).with.offset(-20.f);
        make.centerX.equalTo(self.playbackButton.mas_centerX);
    }];
    self.loadingImageView = loadingImageView;
    
    self.backwardSeekButton.hidden = YES;
    self.forwardSeekButton.hidden = YES;
    
    self.airplayView.delegate = self;
    
    self.timeSlider.resumingAfterSeek = YES;
    self.timeSlider.font = [UIFont srg_regularFontWithSize:14.f];
    self.timeSlider.popUpViewColor = UIColor.whiteColor;
    self.timeSlider.textColor = UIColor.blackColor;
    self.timeSlider.popUpViewWidthPaddingFactor = 1.5f;
    self.timeSlider.popUpViewHeightPaddingFactor = 1.f;
    self.timeSlider.popUpViewCornerRadius = 3.f;
    self.timeSlider.popUpViewArrowLength = 4.f;
    self.timeSlider.dataSource = self;
    
    self.airplayLabel.font = [UIFont srg_regularFontWithTextStyle:UIFontTextStyleFootnote];
    self.errorLabel.font = [UIFont srg_regularFontWithTextStyle:UIFontTextStyleSubheadline];
    
    // Detect all touches on the player view. Other gesture recognizers can be added directly in the storyboard
    // to detect other interactions earlier
    SRGActivityGestureRecognizer *activityGestureRecognizer = [[SRGActivityGestureRecognizer alloc] initWithTarget:self
                                                                                                            action:@selector(resetInactivityTimer:)];
    activityGestureRecognizer.delegate = self;
    [self.playerView addGestureRecognizer:activityGestureRecognizer];
    
    self.fullScreenButton.hidden = [self isFullScreenButtonHidden];
    
    [self reloadData];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self updateInterfaceAnimated:NO];
        [self updateUserInterfaceForServicePlayback];
        [self updateUserInterfaceTogglabilityForAirplayAnimated:NO];
        [self reloadData];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(wirelessRouteDidChange:)
                                                     name:SRGMediaPlayerWirelessRouteDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(screenDidConnect:)
                                                     name:UIScreenDidConnectNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(screenDidDisconnect:)
                                                     name:UIScreenDidDisconnectNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(serviceSettingsDidChange:)
                                                     name:SRGLetterboxServiceSettingsDidChangeNotification
                                                   object:[SRGLetterboxService sharedService]];
    }
    else {
        self.inactivityTimer = nil;                 // Invalidate timer
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIApplicationDidBecomeActiveNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGMediaPlayerWirelessRouteDidChangeNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIScreenDidConnectNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIScreenDidDisconnectNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGLetterboxServiceSettingsDidChangeNotification
                                                      object:[SRGLetterboxService sharedService]];
        
        [[SRGLetterboxService sharedService] removeObserver:self keyPath:@"controller"];
    }
}

#pragma mark Getters and setters

- (void)setController:(SRGLetterboxController *)controller
{
    if (_controller == controller) {
        return;
    }
    
    if (_controller) {
        SRGMediaPlayerController *previousMediaPlayerController = _controller.mediaPlayerController;
        [previousMediaPlayerController removePeriodicTimeObserver:self.periodicTimeObserver];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGLetterboxMetadataDidChangeNotification
                                                      object:_controller];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGLetterboxPlaybackDidFailNotification
                                                      object:_controller];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                      object:previousMediaPlayerController];
        
        if (previousMediaPlayerController.view.superview == self.playerView) {
            [previousMediaPlayerController.view removeFromSuperview];
        }
    }
    
    _controller = controller;
    
    SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
    self.playbackButton.mediaPlayerController = mediaPlayerController;
    self.pictureInPictureButton.mediaPlayerController = mediaPlayerController;
    self.airplayView.mediaPlayerController = mediaPlayerController;
    self.airplayButton.mediaPlayerController = mediaPlayerController;
    self.tracksButton.mediaPlayerController = mediaPlayerController;
    self.timeSlider.mediaPlayerController = mediaPlayerController;
    
    if (controller) {
        SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
        
        @weakify(self)
        @weakify(controller)
        self.periodicTimeObserver = [mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
            @strongify(self)
            @strongify(controller)
            
            self.forwardSeekButton.hidden = ![controller canSeekForward];
            self.backwardSeekButton.hidden = ![controller canSeekBackward];
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(mediaMetadataDidChange:)
                                                     name:SRGLetterboxMetadataDidChangeNotification
                                                   object:controller];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(mediaPlaybackDidFail:)
                                                     name:SRGLetterboxPlaybackDidFailNotification
                                                   object:controller];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateDidChange:)
                                                     name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                   object:mediaPlayerController];
        
        [self.playerView insertSubview:mediaPlayerController.view aboveSubview:self.imageView];
        [mediaPlayerController.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.playerView);
        }];

        // Automatically resumes in the view when displayed and if picture in picture was active
        if ([SRGLetterboxService sharedService].controller == self.controller) {
            [[SRGLetterboxService sharedService] stopPictureInPictureRestoreUserInterface:NO];
        }
    }
}

- (void)setDelegate:(id<SRGLetterboxViewDelegate>)delegate
{
    _delegate = delegate;
    self.fullScreenButton.hidden = [self isFullScreenButtonHidden];
}

- (void)setFullScreen:(BOOL)fullScreen
{
    [self setFullScreen:fullScreen animated:NO];
}

- (void)setFullScreen:(BOOL)fullScreen animated:(BOOL)animated
{
    if (_fullScreen == fullScreen) {
        return;
    }
    
    if (self.fullScreenAnimationRunning) {
        SRGLetterboxLogInfo(@"view", @"A full screen animation is already running");
        return;
    }
    
    self.fullScreenAnimationRunning = YES;
    
    if ([self.delegate respondsToSelector:@selector(letterboxView:toggleFullScreen:animated:withCompletionHandler:)]) {
        [self.delegate letterboxView:self toggleFullScreen:fullScreen animated:animated withCompletionHandler:^(BOOL finished) {
            if (finished) {
                self.fullScreenButton.selected = fullScreen;
                _fullScreen = fullScreen;
            }
            self.fullScreenAnimationRunning = NO;
        }];
    }
}

- (void)setInactivityTimer:(NSTimer *)inactivityTimer
{
    [_inactivityTimer invalidate];
    _inactivityTimer = inactivityTimer;
}

- (BOOL)isPlayingInAirplayWithoutMirroring
{
    if (! [AVAudioSession srg_isAirplayActive]) {
        return NO;
    }

    if (! [UIScreen srg_isMirroring]) {
        return YES;
    }
    
    AVPlayer *player = self.controller.mediaPlayerController.player;
    if (! player) {
        return NO;
    }
    
    // If the player switches to external playback, then it does not mirror the display
    return player.usesExternalPlaybackWhileExternalScreenIsActive;
}

#pragma mark UI

- (void)setUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated togglable:(BOOL)togglable
{
    [self setUserInterfaceHidden:hidden animated:animated togglable:togglable initiatedByUser:YES];
}

- (void)setUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated togglable:(BOOL)togglable initiatedByUser:(BOOL)initiatedByUser
{
    // If usual non-mirrored Airplay playback is active, do not let the user change the current state
    if ([self isPlayingInAirplayWithoutMirroring] && initiatedByUser) {
        if (! togglable) {
            self.wasUserInterfaceTogglable = NO;
        }
        else {
            SRGLetterboxLogWarning(@"view", @"The user interface state cannot be changed while Airplay playback is active");
            return;
        }
    }
    
    // Temporarily allow toggling the interface
    self.userInterfaceTogglable = YES;
    
    [self setUserInterfaceHidden:hidden animated:animated];
    if (togglable) {
        [self resetInactivityTimer];
    }
    
    // Apply the setting
    self.userInterfaceTogglable = togglable;
}

- (void)setUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (! self.userInterfaceTogglable) {
        return;
    }
    
    if (self.userInterfaceHidden == hidden) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(letterboxViewWillAnimateUserInterface:)]) {
        _inWillAnimateUserInterface = YES;
        [self.delegate letterboxViewWillAnimateUserInterface:self];
        _inWillAnimateUserInterface = NO;
    }
    
    void (^animations)(void) = ^{
        CGFloat alpha = hidden ? 0.f : 1.f;
        self.controlsView.alpha = alpha;
        self.animations ? self.animations(hidden) : nil;
    };
    void (^completion)(BOOL) = ^(BOOL finished) {
        if (finished) {
            self.userInterfaceHidden = hidden;
        }
        self.completion ? self.completion(finished) : nil;
        
        self.animations = nil;
        self.completion = nil;
    };
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:animations completion:completion];
    }
    else {
        animations();
        completion(YES);
    }
}

- (void)updateInterfaceAnimated:(BOOL)animated
{
    void (^animations)(void) = ^{
        SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
        
        if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying) {
            // Hide if playing a video in Airplay or if "true screen mirroring" (device screen copy with no full-screen
            // playbackl on the external device) is used
            SRGMedia *media = self.controller.media;
            BOOL hidden = (media.mediaType == SRGMediaTypeVideo) && ! [self isPlayingInAirplayWithoutMirroring];
            self.imageView.alpha = hidden ? 0.f : 1.f;
            mediaPlayerController.view.alpha = hidden ? 1.f : 0.f;
            
            [self resetInactivityTimer];
            
            if (!self.showingPopup) {
                self.showingPopup = YES;
                [self.timeSlider showPopUpViewAnimated:YES];
            }
        }
        else if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateEnded) {
            self.imageView.alpha = 1.f;
            mediaPlayerController.view.alpha = 0.f;
            
            [self.timeSlider hidePopUpViewAnimated:YES];
            self.showingPopup = NO;
            
            [self setUserInterfaceHidden:NO animated:YES];
        }
        
        self.loadingImageView.alpha = (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying
                                       || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePaused
                                       || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateEnded
                                       || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle) ? 0.f : 1.f;
    };
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:animations];
    }
    else {
        animations();
    }
}

- (void)updateUserInterfaceTogglabilityForAirplayAnimated:(BOOL)animated
{
    if ([self isPlayingInAirplayWithoutMirroring]) {
        // If the user interface was togglable, disable and force display, otherwise keep the state as it was
        if (self.userInterfaceTogglable) {
            self.wasUserInterfaceTogglable = YES;
            [self setUserInterfaceHidden:NO animated:animated togglable:NO initiatedByUser:NO];
        }
    }
    else {
        if (self.wasUserInterfaceTogglable) {
            [self setUserInterfaceHidden:NO animated:animated togglable:YES initiatedByUser:NO];
        }
    }
}

- (void)updateUserInterfaceForServicePlayback
{
    self.airplayButton.alwaysHidden = ! self.controller.backgroundServicesEnabled;
    self.pictureInPictureButton.alwaysHidden = ! self.controller.pictureInPictureEnabled;
}

- (void)resetInactivityTimer
{
    self.inactivityTimer = [NSTimer scheduledTimerWithTimeInterval:4. target:self selector:@selector(hideInterface:) userInfo:nil repeats:NO];
}

- (void)animateAlongsideUserInterfaceWithAnimations:(void (^)(BOOL))animations completion:(void (^)(BOOL finished))completion
{
    if (! _inWillAnimateUserInterface) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"-animateAlongsideUserInterfaceWithAnimations:completion: can omnly be called from within the -animateAlongsideUserInterfaceWithAnimations: method of the Letterbox view delegate"
                                     userInfo:nil];
    }
    
    self.animations = animations;
    self.completion = completion;
}

- (BOOL)isFullScreenButtonHidden
{
    return ! self.delegate || ! [self.delegate respondsToSelector:@selector(letterboxView:toggleFullScreen:animated:withCompletionHandler:)];
}

#pragma mark Gesture recognizers

- (void)resetInactivityTimer:(UIGestureRecognizer *)gestureRecognizer
{
    [self resetInactivityTimer];
    [self setUserInterfaceHidden:NO animated:YES];
}

- (IBAction)hideUserInterface:(UIGestureRecognizer *)gestureRecognizer
{
    [self setUserInterfaceHidden:YES animated:YES];
}

#pragma mark Timers

- (void)hideInterface:(NSTimer *)timer
{
    // Only auto-hide the UI when it makes sense (e.g. not when the player is paused or loading). When the state
    // of the player returns to playing, the inactivity timer will be reset (see -playbackStateDidChange:)
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying
            || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateSeeking
            || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateStalled
            || ! self.errorView.hidden) {
        [self setUserInterfaceHidden:YES animated:YES];
    }
}

#pragma mark Actions

- (IBAction)seekBackward:(id)sender
{
    [self.controller seekBackwardWithCompletionHandler:nil];
}

- (IBAction)seekForward:(id)sender
{
    [self.controller seekForwardWithCompletionHandler:nil];
}

- (IBAction)toggleFullScreen:(id)sender
{
    [self setFullScreen:!self.isFullScreen animated:YES];
}

#pragma mark Data display

- (void)reloadData
{
    if (self.controller.error) {
        self.errorView.hidden = NO;
        self.errorLabel.text = self.controller.error.localizedDescription;
    }
    else if (self.controller.media) {
        self.errorView.hidden = YES;
        [self.imageView srg_requestImageForObject:self.controller.media withScale:SRGImageScaleLarge placeholderImageName:@"placeholder_media-180"];
    }
    else if (self.controller.URN) {
        self.errorView.hidden = YES;
    }
    else {
        NSError *error = [NSError errorWithDomain:SRGLetterboxErrorDomain
                                             code:SRGLetterboxErrorCodeNotFound
                                         userInfo:@{ NSLocalizedDescriptionKey : SRGLetterboxLocalizedString(@"No media", @"Text displayed when no media is available for playback") }];
        self.errorView.hidden = NO;
        self.errorLabel.text = error.localizedDescription;
    }
}

#pragma mark ASValueTrackingSliderDataSource protocol

- (NSString *)slider:(ASValueTrackingSlider *)slider stringForValue:(float)value;
{
    if (self.controller.media.contentType == SRGContentTypeLivestream) {
        return (self.timeSlider.isLive) ? NSLocalizedString(@"Live", nil) : self.timeSlider.valueString;
    }
    else {
        return self.timeSlider.valueString ?: @"--:--";
    }
}

#pragma mark SRGAirplayViewDelegate protocol

- (void)airplayView:(SRGAirplayView *)airplayView didShowWithAirplayRouteName:(NSString *)routeName
{
    self.airplayLabel.text = SRGAirplayRouteDescription();
}

#pragma mark UIGestureRecognizerDelegate protocol

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark Notifications

- (void)mediaMetadataDidChange:(NSNotification *)notification
{
    [self reloadData];
    
    if (! self.errorView.hidden) {
        self.errorView.hidden = YES;
        [self resetInactivityTimer];
    }
}

- (void)mediaPlaybackDidFail:(NSNotification *)notification
{
    [self reloadData];
}

- (void)playbackStateDidChange:(NSNotification *)notification
{
    [self updateInterfaceAnimated:YES];
    [self updateUserInterfaceTogglabilityForAirplayAnimated:YES];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self setUserInterfaceHidden:NO animated:YES];
    [self updateInterfaceAnimated:YES];
}

- (void)wirelessRouteDidChange:(NSNotification *)notification
{
    [self updateInterfaceAnimated:YES];
    [self updateUserInterfaceTogglabilityForAirplayAnimated:YES];
}

- (void)screenDidConnect:(NSNotification *)notification
{
    [self updateInterfaceAnimated:YES];
}

- (void)screenDidDisconnect:(NSNotification *)notification
{
    [self updateInterfaceAnimated:YES];
}

- (void)serviceSettingsDidChange:(NSNotification *)notification
{
    [self updateUserInterfaceForServicePlayback];
}

@end

static void commonInit(SRGLetterboxView *self)
{
    UIView *view = [[[NSBundle srg_letterboxBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] firstObject];
    [self addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    self.userInterfaceHidden = NO;
    self.userInterfaceTogglable = YES;
}
